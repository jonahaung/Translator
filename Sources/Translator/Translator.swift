//
//  Translator.swift
//  OCRKeyboardCamera
//
//  Created by Aung Ko Min on 25/4/22.
//

import Foundation
import NaturalLanguage

public class Translator {
    
    struct API {
        static let base = "https://api.mymemory.translated.net/get?"
        struct Translate {
            static let httpMethod = "GET"
            static let url = API.base
            
            
            struct QueryItem {
                static func text(for value: String) -> URLQueryItem {
                    URLQueryItem(name: "q", value: value.lowercased())
                }
                static func languagePair(from fromLangeuage: NLLanguage, to toLanguage: NLLanguage) -> URLQueryItem {
                    URLQueryItem(name: "langpair", value: "\(fromLangeuage.rawValue)|\(toLanguage.rawValue)")
                }
                static func translatorType() -> URLQueryItem {
                    URLQueryItem(name: "mt", value: "1")
                }
                static func ipAddress(for value: String) -> URLQueryItem {
                    URLQueryItem(name: "ip", value: value)
                }
                static func email(for value: String) -> URLQueryItem {
                    URLQueryItem(name: "de", value: value)
                }
            }
        }
    }
    
    public static let shared = Translator()
    private let session = URLSession.shared
    
    public init() {
        
    }
    
    
    @available(iOS 15.0.0, *)
    public func translate(text: String, from: NLLanguage, to: NLLanguage) async -> String? {
        let urlRequest = urlRequest(text: text, from: from, to: to)
        do {
            let (data, _) = try await session.data(for: urlRequest)
            guard let string = String(data: data, encoding: .utf8),
                  let dataString = string.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: dataString , options: []),
                  let dictionary = json as? [String: Any],
                  let responseData = dictionary["responseData"] as? NSDictionary,
                  let translated = responseData["translatedText"] as? String else {
                return nil
            }
            return translated.lowercased()
        } catch {
            return nil
        }
    }
    
    public func translate(text: String, from: NLLanguage, to: NLLanguage,  _ completion: @escaping (String?) -> Void) {
        
        let urlRequest = urlRequest(text: text, from: from, to: to)
        
        session.dataTask(with: urlRequest) { (data, response, error) in
            guard
                let response = response as? HTTPURLResponse,
                (200 ..< 300) ~= response.statusCode,
                error == nil,
                let data = data,
                let string = String(data: data, encoding: .utf8),
                let dataString = string.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: dataString , options: []),
                let dictionary = json as? [String: Any],
                let responseData = dictionary["responseData"] as? NSDictionary,
                let translated = responseData["translatedText"] as? String else {
                completion(text)
                return
            }
            completion(translated.lowercased())
        }.resume()
    }
    
    private func urlRequest(text: String, from: NLLanguage, to: NLLanguage) -> URLRequest {
        var queyItems = [API.Translate.QueryItem.text(for: text), API.Translate.QueryItem.languagePair(from: from, to: to), API.Translate.QueryItem.translatorType()]
        if let wifiiAddress = getWiFiAddress() {
            queyItems.append(API.Translate.QueryItem.ipAddress(for: wifiiAddress))
        }
        queyItems.append(API.Translate.QueryItem.email(for: RandomEmailAddress.emailAddress))
        
        var urlComponents = URLComponents(string: API.Translate.url)!
        urlComponents.queryItems = queyItems
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = API.Translate.httpMethod
        return request
    }
    
    private func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                if let interface = ptr?.pointee {
                    let addrFamily = interface.ifa_addr.pointee.sa_family
                    if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                        let name: String = String(cString: interface.ifa_name)
                        if name == "en0" {
                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                            address = String(cString: hostname)
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}
