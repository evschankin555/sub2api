import { describe, expect, it } from 'vitest'

import en from '../locales/en'
import ru from '../locales/ru'
import zh from '../locales/zh'

describe('usage service tier locale keys', () => {
  function collectObjectPaths(value: unknown, prefix = ''): string[] {
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
      return []
    }

    return Object.entries(value as Record<string, unknown>).flatMap(([key, child]) => {
      const path = prefix ? `${prefix}.${key}` : key
      return [path, ...collectObjectPaths(child, path)]
    })
  }

  function getPath(value: Record<string, unknown>, path: string): unknown {
    return path.split('.').reduce<unknown>((current, key) => {
      if (!current || typeof current !== 'object') {
        return undefined
      }
      return (current as Record<string, unknown>)[key]
    }, value)
  }

  it('keeps zh and ru locale key shape compatible with en', () => {
    const enPaths = collectObjectPaths(en)

    for (const [localeName, messages] of [
      ['zh', zh],
      ['ru', ru],
    ] as const) {
      const missing = enPaths.filter((path) => getPath(messages, path) === undefined)
      expect(missing, `${localeName} is missing locale keys`).toEqual([])
    }
  })

  it('contains zh labels for service tier tooltip', () => {
    expect(zh.usage.serviceTier).toBe('服务档位')
    expect(zh.usage.serviceTierPriority).toBe('Fast')
    expect(zh.usage.serviceTierFlex).toBe('Flex')
    expect(zh.usage.serviceTierStandard).toBe('Standard')
  })

  it('contains en labels for service tier tooltip', () => {
    expect(en.usage.serviceTier).toBe('Service tier')
    expect(en.usage.serviceTierPriority).toBe('Fast')
    expect(en.usage.serviceTierFlex).toBe('Flex')
    expect(en.usage.serviceTierStandard).toBe('Standard')
  })

  it('contains ru labels for service tier tooltip', () => {
    expect(ru.usage.serviceTier).toBe('Уровень обслуживания')
    expect(ru.usage.serviceTierPriority).toBe('Fast')
    expect(ru.usage.serviceTierFlex).toBe('Flex')
    expect(ru.usage.serviceTierStandard).toBe('Standard')
  })
})
