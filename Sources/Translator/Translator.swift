//
//  Translator.swift
//  OCRKeyboardCamera
//
//  Created by Aung Ko Min on 25/4/22.
//

import Foundation
import NaturalLanguage

public struct Translator {
    
    struct API {
        static let base = "https://api.mymemory.translated.net/get?"
        struct translate {
            static let method = "GET"
            static let url = API.base
        }
    }
    
    public static let shared = Translator()
    
    public func translate(text: String, from: NLLanguage, to: NLLanguage,  _ completion: @escaping (String?) -> Void) {
        let textQueryItem = URLQueryItem(name: "q", value: text.lowercased())
        let languageQueryItem = URLQueryItem(name: "langpair", value: "\(from.rawValue)|\(to.rawValue)")
        let machineQueryItem = URLQueryItem(name: "mt", value: "1")
        var queyItems = [textQueryItem, languageQueryItem, machineQueryItem]
        if let wifiiAddress = getWiFiAddress() {
            let ipQueryItem = URLQueryItem(name: "ip", value: wifiiAddress)
            queyItems.append(ipQueryItem)
        }
        let emailQueryItem = URLQueryItem(name: "de", value: RandomEmailAddress.emailAddress)
        queyItems.append(emailQueryItem)
        var urlComponents = URLComponents(string: API.translate.url)!
        urlComponents.queryItems = queyItems
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = API.translate.method
        
        URLSession(configuration: .default).dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode, error == nil else {
                completion(nil)
                return
            }
            guard
                let string = String(data: data, encoding: .utf8),
                let dataString = string.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: dataString , options: []),
                let dictionary = json as? [String: Any],
                let responseData = dictionary["responseData"] as? NSDictionary,
                let translated = responseData["translatedText"] as? String else {
                completion(text)
                return
            }
            
            let lowerCased = translated.lowercased()
            completion(lowerCased)
        }.resume()
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
