//
//  Bundle.swift
//  BundleSwizzling
//
//  Created by Лайм HD on 01.08.2025.
//

import Foundation

/**
 Расширение Bundle для динамической подмены bundleIdentifier через swizzling.
 Подменяет идентификатор для Bundle.main во всех Objective-C точках чтения:
 `bundleIdentifier`, `infoDictionary["CFBundleIdentifier"]` и `object(forInfoDictionaryKey:)`.
 
 Не перехватывает чтение через C-API (`CFBundleGetIdentifier`), поэтому SDK, использующие его, подмену не увидят.
 Предназначено для тестирования и демо-приложений.

 ### Пример использования:
 ```swift
 // Подменить bundleIdentifier на новый
 Bundle.swizzleBundleIdentifier(to: "com.example.test")
 print(Bundle.main.bundleIdentifier) // com.example.test
 
 // Сбросить подмену
 Bundle.resetBundleIdentifierSwizzling()
 print(Bundle.main.bundleIdentifier) // оригинальный bundleID
 ```
*/
public extension Bundle {
    /**
     Подменяет bundleID для Bundle.main на указанный newBundleID.
     Первый вызов выполняет swizzling, повторные меняют только значение bundleID.
     
     - Parameter newBundleID: Новый идентификатор бандла, который будет возвращаться для Bundle.main.
     
     ### Пример:
     ```swift
     Bundle.swizzleBundleIdentifier(to: "com.example.test")
     print(Bundle.main.bundleIdentifier) // com.example.test
     ```
     */
    static func swizzleBundleIdentifier(to newBundleID: String) {
        SwizzlingState.lock.lock()
        defer { SwizzlingState.lock.unlock() }
        
        // Сохраняем новый bundleID в классе Bundle
        objc_setAssociatedObject(Bundle.self, &AssociatedKeys.bundleIdentifier, newBundleID, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Предотвращаем повторный swizzling
        guard !SwizzlingState.hasSwizzled else { return }
        
        guard exchangeImplementations() else {
            print("⚠️ Bundle swizzling failed: methods not found")
            return
        }
        SwizzlingState.hasSwizzled = true
        
        print("✅ Bundle ID swizzled to: \(newBundleID)")
    }
    
    /**
     Сбрасывает swizzling и возвращает оригинальное поведение bundleIdentifier.
     Используется для тестирования или возврата к исходному состоянию.
     
     ### Пример:
     ```swift
     Bundle.resetBundleIdentifierSwizzling()
     ```
     */
    static func resetBundleIdentifierSwizzling() {
        SwizzlingState.lock.lock()
        defer { SwizzlingState.lock.unlock() }
        
        guard SwizzlingState.hasSwizzled, exchangeImplementations() else { return }
        objc_setAssociatedObject(Bundle.self, &AssociatedKeys.bundleIdentifier, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        SwizzlingState.hasSwizzled = false
    }
    
    
}

// MARK: - Swizzled methods

private extension Bundle {
    /**
     Пары селекторов «оригинальный метод — подменяющий метод».
     */
    static var swizzlingPairs: [(original: Selector, swizzled: Selector)] {
        [
            (#selector(getter: Bundle.bundleIdentifier), #selector(Bundle.swizzled_bundleIdentifier)),
            (#selector(getter: Bundle.infoDictionary), #selector(Bundle.swizzled_infoDictionary)),
            (NSSelectorFromString("objectForInfoDictionaryKey:"), NSSelectorFromString("swizzled_objectForInfoDictionaryKey:"))
        ]
    }
    
    /**
     Возвращает кастомный bundleID, если self является Bundle.main и подмена установлена.
     */
    var customBundleID: String? {
        guard self == Bundle.main else { return nil }
        return objc_getAssociatedObject(Bundle.self, &AssociatedKeys.bundleIdentifier) as? String
    }
    
    /**
     Меняет местами реализации всех пар методов. Повторный вызов возвращает исходное состояние.
     
     - Returns: true, если все методы найдены и обменяны.
     */
    static func exchangeImplementations() -> Bool {
        let methods = swizzlingPairs.compactMap { pair -> (Method, Method)? in
            guard let original = class_getInstanceMethod(Bundle.self, pair.original),
                  let swizzled = class_getInstanceMethod(Bundle.self, pair.swizzled) else { return nil }
            return (original, swizzled)
        }
        guard methods.count == swizzlingPairs.count else { return false }
        methods.forEach { method_exchangeImplementations($0.0, $0.1) }
        return true
    }
    
    /**
     Подменяющая реализация bundleIdentifier. После обмена реализациями вызов
     swizzled_bundleIdentifier() выполняет оригинальный метод.
     */
    @objc func swizzled_bundleIdentifier() -> String? {
        customBundleID ?? swizzled_bundleIdentifier()
    }
    /**
     Подменяющая реализация infoDictionary: заменяет CFBundleIdentifier для Bundle.main.
     */
    @objc func swizzled_infoDictionary() -> [String: Any]? {
        var info = swizzled_infoDictionary()
        if let customBundleID {
            info?["CFBundleIdentifier"] = customBundleID
        }
        return info
    }
    /**
     Подменяющая реализация object(forInfoDictionaryKey:): заменяет значение CFBundleIdentifier для Bundle.main.
     - Parameter key: Ключ Info.plist.
     */
    @objc(swizzled_objectForInfoDictionaryKey:)
    func swizzled_object(forInfoDictionaryKey key: String) -> Any? {
        if key == "CFBundleIdentifier", let customBundleID {
            return customBundleID
        }
        return swizzled_object(forInfoDictionaryKey: key)
    }
    
    
}

/**
 Состояние swizzling: флаг выполненной подмены и блокировка для потокобезопасного доступа.
 */
private enum SwizzlingState {
    /**
     Флаг, указывающий, был ли уже выполнен swizzling методов Bundle.
     */
    static var hasSwizzled = false
    
    /**
     Блокировка, защищающая флаг и обмен реализациями.
     */
    static let lock = NSLock()
    
    
}

/**
 Структура для хранения ключей, используемых при работе с associated objects.
 */
private struct AssociatedKeys {
    /**
     Ключ для хранения кастомного bundleIdentifier в associated objects.
     */
    static var bundleIdentifier: UInt8 = 0
    
    
}
