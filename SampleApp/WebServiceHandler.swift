//
//  WebServiceHandler.swift
//  Tracker
//
//  Created by Anshuman Singh on 8/24/19.
//  Copyright © 2019 Anshuman Singh. All rights reserved.
//

import Foundation

protocol WebServiceProtocol: class {
    
    func startAnimation()
    func stopAnimation()
    func parseData(data: Data)
}

extension WebServiceProtocol {
    
    func parseData(data: Data){}
}

class WebServiceHandler: NSObject {
    
    weak var delegate: WebServiceProtocol?
  
    private var latitude: Double?
    
    private var longitude: Double?
    
    private var datasource: String?
    
    private var dataUpdateDelegate: PareserDataUpdateDelegate?
    
    private var apiKey: String? {
        
        return Utility.readValue(fromplistFile: "Config", forKey: "API Key")
    }
    
    
    init?(with baseurl: String?, latitude: Double, longitude: Double, parserDelegate delegate:PareserDataUpdateDelegate) {

        super.init()
        guard let _apiKey = self.apiKey else {
            
            Logger.debugLog(Constants.ErrorMessage.webServiceHandlerErrorNoAPIKey)
            return nil
        }
        
        guard let baseURL = baseurl else {

            Logger.debugLog(Constants.ErrorMessage.webServiceHandlerErrorNoBaseURL)
            return nil
        }
        
        setup(lat: latitude, long: longitude, baseurl: baseURL, apiKey: _apiKey, parserDelegate: delegate)
    }
    

    private func setup(lat latitude: Double, long longitude: Double, baseurl baseURL: String, apiKey _apiKey: String, parserDelegate delegate: PareserDataUpdateDelegate) {
        
        let coordinates = String(format:"\(latitude),\(longitude)")
        self.datasource = baseURL + _apiKey + "/" + coordinates
        
        if let langStr = Locale.current.languageCode, let dataSrc = self.datasource {
            
            self.datasource = addLocaleInfoInRequest(request: dataSrc, localeInfo: langStr)
        }
        
        self.latitude = latitude
        self.longitude = longitude
        self.dataUpdateDelegate = delegate
    }

    
    private func addLocaleInfoInRequest(request: String, localeInfo: String) -> String {
        
        let req = request + "?" + "lang=" + localeInfo
        return req
    }

    private func prepareRequest(source: String) -> URL? {
        
        guard let url = URL(string: source) else { return nil }
        return url
        
    }
    
    func fetchData() {
 
        self.delegate?.startAnimation()
        DispatchQueue.global(qos: .utility).async { [weak self]  in
            
            guard let weakSelf = self, let dataSrc = weakSelf.datasource else {
                
                Logger.debugLog(Constants.ErrorMessage.badDataSource)
                return
            }
            
            guard let url = weakSelf.prepareRequest(source: dataSrc) else {
                
                Logger.debugLog(Constants.ErrorMessage.badURL)
                return
            }
            
            Logger.debugLog("url --> \(url)")
            
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                
                guard let newData = data else {
                    
                    Logger.debugLog(Constants.ErrorMessage.noDataAvailable)
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { //TODO: Delay induced for demo purpose
                    
                    let responseParser = Parser(newData, delegate: weakSelf.dataUpdateDelegate)
                    responseParser.start()
                    weakSelf.delegate?.stopAnimation()
                    
                })
                
            }).resume()
            
            }
        }
    
}
    




