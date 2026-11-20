# BundleSwizzling

Подмена `bundleIdentifier` главного бандла (`Bundle.main`) в рантайме. Нужна для тестирования и демо-приложений, когда рекламный или другой SDK проверяет bundle ID, а менять идентификатор приложения в Xcode нежелательно.

> Только для тестовых и демо-приложений. Не используйте в релизных сборках.

## Использование

```swift
import BundleSwizzling

// Вызывать до инициализации SDK
Bundle.swizzleBundleIdentifier(to: "com.example.test")
print(Bundle.main.bundleIdentifier) // com.example.test

// Сбросить подмену
Bundle.resetBundleIdentifierSwizzling()
```

## Что подменяется

Для `Bundle.main` подменяется значение во всех Objective-C точках чтения:

- `bundleIdentifier`
- `infoDictionary["CFBundleIdentifier"]`
- `object(forInfoDictionaryKey: "CFBundleIdentifier")`

## Ограничения

- Чтение через C-API (`CFBundleGetIdentifier(CFBundleGetMainBundle())`) не перехватывается.
- Подмену нужно устанавливать до инициализации SDK, которому она нужна.

## Установка

Swift Package Manager:

```swift
.package(url: "https://github.com/SwiftExtensions/BundleSwizzling", from: "1.0.0")
```
