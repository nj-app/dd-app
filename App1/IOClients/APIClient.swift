//
//  APIClient.swift
//  App1
//
//  Created by John Grese on 7/31/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

enum HTTPMethods: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

class APIClient: NSObject {
    static var shared = APIClient()
    private let baseURL = "https://iotstripes-ddapi.azurewebsites.net"
    private let deviceEventPath = "/api/device-events"
    private let sensorDataPath = "/api/sensor-data"

    private override init() {
        super.init()
    }

    func fetchEvents(userID: String, deviceID: String, completion: ((_ events: Array<EventData>, _ success: Bool) -> Void)?) {
        let eventURL = baseURL + deviceEventPath
        self.request(url: eventURL, method: HTTPMethods.get, data: nil) {result, success in
            print("Events fetched: ", result ?? "")
            if let completion = completion, let result = result as? Array<EventData> {
                completion(result, false)
            }
        }
    }

    func saveEvents(events: Array<EventData>, userID: String, deviceID: String, completion: ((_ success: Bool) -> Void)?) {

        // Generate concurrent API calls for all events.
        let dispatchGroup = DispatchGroup()
        let eventURL = baseURL + deviceEventPath
        var statuses: Array<Bool> = []

        for event in events {
            dispatchGroup.enter() // start async block.
            let eventData: Dictionary<String, Any> = [
                "event_id": event.event_id,
                "event_type": event.event_type,
                "device_id": deviceID,
                "user_id": userID,
                "timestamp": event.timestamp
            ]

            self.request(url: eventURL, method: HTTPMethods.post, data: eventData) {response, success in
                if !success {
                    print("Error saving event: ", response ?? "")
                }
                DispatchQueue.main.async {
                    statuses.append(success)
                    dispatchGroup.leave() // resolve async block.
                }
            }
        }
        // Fire requests in parallel:
        dispatchGroup.notify(queue: .main) {
            let allSuccessful = statuses.reduce(true, {a, b in a && b})
            if let completion = completion {
                completion(allSuccessful)
            }
        }
    }

    func saveSensorData(sensorDataItems: Array<SensorData>, userID: String, deviceID: String, completion: ((_ success: Bool) -> Void)?) {

        // Generate concurrent API calls for all sensor data..
        let dispatchGroup = DispatchGroup()
        let dataURL = baseURL + sensorDataPath
        var statuses: Array<Bool> = []

        for data in sensorDataItems {
            dispatchGroup.enter() // start async block.
            let sensorData: Dictionary<String, Any> = [
                "data_id": data.data_id,
                "device_id": deviceID,
                "user_id": userID,
                "timestamp": data.timestamp,
                "humidity": data.humidity,
                "temperature": data.temperature
            ]

            self.request(url: dataURL, method: HTTPMethods.post, data: sensorData) {response, success in
                if !success {
                    print("Error saving sensor data: ", response ?? "")
                }
                DispatchQueue.main.async {
                    statuses.append(success)
                    dispatchGroup.leave() // resolve async block.
                }
            }
        }
        // Fire requests in parallel:
        dispatchGroup.notify(queue: .main) {
            let allSuccessful = statuses.reduce(true, {a, b in a && b})
            if let completion = completion {
                print("Sensor data saved.")
                completion(allSuccessful)
            }
        }
    }

    private func request(url: String, method: HTTPMethods, data: Dictionary<String, Any>?, completion: ((_ result: Any?, _ success: Bool) -> Void)?) {

        guard let url = URL(string: url) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            if let data = data {
                request.httpBody = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            }
        } catch let error {
            print(error.localizedDescription)
            if let completion = completion {
                completion(nil, false)
            }
        }


        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            guard error == nil else {
                print("Request error: ", error?.localizedDescription ?? "")
                if let completion = completion {
                    completion(nil, false)
                }
                return
            }

            guard let data = data else {
                print("No data in response: ", error?.localizedDescription ?? "")
                if let completion = completion {
                    completion(nil, true)
                }
                return
            }

            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print("Response: ", json)
                    
                    if let completion = completion {
                        completion(json, true)
                    }
                }
            } catch let error {
                print(error.localizedDescription)
                if let completion = completion {
                    completion(nil, false)
                }
            }
        })
        task.resume()
    }
}
