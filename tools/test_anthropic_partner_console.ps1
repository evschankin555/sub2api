param(
    [string]$EnvFile = (Join-Path $PSScriptRoot "..\\.env.partner-console.local")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-EnvFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Env file not found: $Path"
    }

    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
            continue
        }

        $eqIndex = $trimmed.IndexOf("=")
        if ($eqIndex -lt 1) {
            continue
        }

        $name = $trimmed.Substring(0, $eqIndex).Trim()
        $value = $trimmed.Substring($eqIndex + 1).Trim()

        if (
            ($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        $values[$name] = $value
    }

    return $values
}

function Get-EnvValue {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($Config.ContainsKey($Name) -and $null -ne $Config[$Name]) {
        return [string]$Config[$Name]
    }

    return ""
}

function Invoke-JsonRequest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Method,
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [Parameter(Mandatory = $true)]
        [hashtable]$Headers,
        [object]$Body = $null
    )

    $requestParams = @{
        Method          = $Method
        Uri             = $Uri
        Headers         = $Headers
        UseBasicParsing = $true
        TimeoutSec      = 60
    }

    if ($null -ne $Body) {
        $requestParams["ContentType"] = "application/json"
        $requestParams["Body"] = ($Body | ConvertTo-Json -Depth 20 -Compress)
    }

    try {
        $response = Invoke-WebRequest @requestParams
        $json = $null
        if (-not [string]::IsNullOrWhiteSpace($response.Content)) {
            $json = $response.Content | ConvertFrom-Json
        }
        return @{
            Ok         = $true
            StatusCode = [int]$response.StatusCode
            Json       = $json
            RawBody    = $response.Content
        }
    } catch {
        $statusCode = 0
        $rawBody = ""
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $rawBody = $reader.ReadToEnd()
            $reader.Dispose()
        }

        $json = $null
        if (-not [string]::IsNullOrWhiteSpace($rawBody)) {
            try {
                $json = $rawBody | ConvertFrom-Json
            } catch {
            }
        }

        return @{
            Ok         = $false
            StatusCode = $statusCode
            Json       = $json
            RawBody    = $rawBody
            ErrorText  = $_.Exception.Message
        }
    }
}

function Get-DisplayText {
    param(
        [AllowNull()]
        [string]$Primary,
        [AllowNull()]
        [string]$Fallback
    )

    if (-not [string]::IsNullOrWhiteSpace($Primary)) {
        return $Primary
    }

    return $Fallback
}

function Get-AssistantTextFromChatCompletions {
    param([object]$Json)

    if ($null -eq $Json -or $null -eq $Json.choices -or $Json.choices.Count -lt 1) {
        return ""
    }

    $content = $Json.choices[0].message.content
    if ($content -is [string]) {
        return $content
    }

    return ""
}

function Get-AssistantTextFromMessages {
    param([object]$Json)

    if ($null -eq $Json -or $null -eq $Json.content) {
        return ""
    }

    $parts = @()
    foreach ($item in $Json.content) {
        if ($item.type -eq "text" -and -not [string]::IsNullOrWhiteSpace($item.text)) {
            $parts += $item.text
        }
    }

    return ($parts -join " ").Trim()
}

$envPath = [System.IO.Path]::GetFullPath($EnvFile)
$config = Read-EnvFile -Path $envPath

$baseUrl = (Get-EnvValue -Config $config -Name "PARTNER_BASE_URL").Trim().TrimEnd("/")
$apiKey = (Get-EnvValue -Config $config -Name "PARTNER_API_KEY").Trim()
$openAIModel = (Get-EnvValue -Config $config -Name "PARTNER_OPENAI_MODEL").Trim()
$anthropicModel = (Get-EnvValue -Config $config -Name "PARTNER_ANTHROPIC_MODEL").Trim()
$negativeModel = (Get-EnvValue -Config $config -Name "PARTNER_NEGATIVE_MODEL").Trim()

if ([string]::IsNullOrWhiteSpace($baseUrl)) {
    throw "PARTNER_BASE_URL is missing in $envPath"
}
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw "PARTNER_API_KEY is missing in $envPath"
}
if ([string]::IsNullOrWhiteSpace($openAIModel)) {
    throw "PARTNER_OPENAI_MODEL is missing in $envPath"
}
if ([string]::IsNullOrWhiteSpace($anthropicModel)) {
    throw "PARTNER_ANTHROPIC_MODEL is missing in $envPath"
}

$authHeaders = @{
    Authorization = "Bearer $apiKey"
}

Write-Host "Env file:" $envPath
Write-Host "Base URL:" $baseUrl
Write-Host ""

$models = Invoke-JsonRequest -Method "GET" -Uri "$baseUrl/v1/models" -Headers $authHeaders
if ($models.Ok) {
    $modelIds = @()
    if ($models.Json -and $models.Json.data) {
        foreach ($item in $models.Json.data) {
            if ($item.id) {
                $modelIds += [string]$item.id
            }
        }
    }

    Write-Host "[OK] GET /v1/models -> HTTP $($models.StatusCode)"
    if ($modelIds.Count -gt 0) {
        Write-Host ("Models: " + ($modelIds -join ", "))
    } else {
        Write-Host "Models: response parsed, but no model ids were extracted"
    }
} else {
    Write-Host "[FAIL] GET /v1/models -> HTTP $($models.StatusCode)"
    Write-Host (Get-DisplayText -Primary $models.RawBody -Fallback $models.ErrorText)
}

Write-Host ""

$chatBody = @{
    model      = $openAIModel
    messages   = @(
        @{
            role    = "user"
            content = "Reply with OK only."
        }
    )
    max_tokens = 32
}
$chat = Invoke-JsonRequest -Method "POST" -Uri "$baseUrl/v1/chat/completions" -Headers $authHeaders -Body $chatBody
if ($chat.Ok) {
    $text = Get-AssistantTextFromChatCompletions -Json $chat.Json
    Write-Host "[OK] POST /v1/chat/completions model=$openAIModel -> HTTP $($chat.StatusCode)"
    if ($text) {
        Write-Host ("Reply: " + $text)
    }
} else {
    Write-Host "[FAIL] POST /v1/chat/completions model=$openAIModel -> HTTP $($chat.StatusCode)"
    Write-Host (Get-DisplayText -Primary $chat.RawBody -Fallback $chat.ErrorText)
}

Write-Host ""

$messageHeaders = @{
    "x-api-key"         = $apiKey
    "anthropic-version" = "2023-06-01"
}
$messageBody = @{
    model      = $anthropicModel
    max_tokens = 32
    messages   = @(
        @{
            role    = "user"
            content = "Reply with OK only."
        }
    )
}
$messages = Invoke-JsonRequest -Method "POST" -Uri "$baseUrl/v1/messages" -Headers $messageHeaders -Body $messageBody
if ($messages.Ok) {
    $text = Get-AssistantTextFromMessages -Json $messages.Json
    Write-Host "[OK] POST /v1/messages model=$anthropicModel -> HTTP $($messages.StatusCode)"
    if ($text) {
        Write-Host ("Reply: " + $text)
    }
} else {
    Write-Host "[FAIL] POST /v1/messages model=$anthropicModel -> HTTP $($messages.StatusCode)"
    Write-Host (Get-DisplayText -Primary $messages.RawBody -Fallback $messages.ErrorText)
}

if (-not [string]::IsNullOrWhiteSpace($negativeModel)) {
    Write-Host ""

    $negativeBody = @{
        model      = $negativeModel
        messages   = @(
            @{
                role    = "user"
                content = "Reply with OK only."
            }
        )
        max_tokens = 32
    }
    $negative = Invoke-JsonRequest -Method "POST" -Uri "$baseUrl/v1/chat/completions" -Headers $authHeaders -Body $negativeBody
    if ($negative.Ok) {
        Write-Host "[WARN] Negative check unexpectedly succeeded for model=$negativeModel -> HTTP $($negative.StatusCode)"
        $text = Get-AssistantTextFromChatCompletions -Json $negative.Json
        if ($text) {
            Write-Host ("Reply: " + $text)
        }
    } else {
        Write-Host "[EXPECTED FAIL] Negative check model=$negativeModel -> HTTP $($negative.StatusCode)"
        Write-Host (Get-DisplayText -Primary $negative.RawBody -Fallback $negative.ErrorText)
    }
}
