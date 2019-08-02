//
//  AppState.swift
//  App1
//
//  Created by John Grese on 8/1/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

// A simple singleton object used to store the current
// state of the application.  Note that it is stored in
// a JSON file in the filesystem just for demo purposes.
// CoreData should be used in the long-run to persist data.

struct EventJSON: Codable {
    var uuid: String
    var timestamp: String
    var eventType: Int
}

struct DeviceJSON: Codable {
    var id: Int
    var uuid: String
    var name: String
    var status: Int
    var events: Array<EventJSON>
}

struct UserJSON: Codable {
    var id: Int
    var uuid: String
    var name: String
    var email: String
}

struct AccountJSON: Codable {
    var user: UserJSON
    var devices: Array<DeviceJSON>
}

class AppState {
    static var shared = AppState()

    var account: Account?
    private var fileName:String = "dd-app-state.json"

    // Save state to file system.
    func saveState() {
        if let account = account, let accountData = accountToJSON(account), let fileURL = getFileURL() {
            do {
                try accountData.write(to: fileURL)
            } catch {
                print("Error occurred while persisting account JSON file")
            }
        }
    }

    // Reads the state from filesystem.
    func readState() {
        if let fileURL = getFileURL() {
            if let jsonData = try? Data(contentsOf: fileURL),
               let account = accountFromJSON(jsonData) {
                self.account = account
            } else {
                print("Error occurred while reading account JSON file")
            }
        }
    }

    func restore() {
        if !stateFileExists() {
            // Generate account data for demo:
            print("Generating demo account")
            account = generateDemoAccount()
            saveState()
        } else {
            // Restore the state from JSON file:
            print("Restoring state from filesystem")
            readState()
        }
    }

    func destroy() {
        if let fileURL = getFileURL() {
            print("Deleting state file.")
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Error occurred while deleting state file.")
            }
        }
    }

    private func getFileURL() -> URL? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            // Read the JSON file, and decode the JSON...
            return dir.appendingPathComponent(fileName)
        }
        return nil
    }

    private func accountToJSON(_ account: Account) -> Data? {
        let user = account.user
        let jsonUser: UserJSON = UserJSON(id: user.dbId, uuid: user.userId, name: user.name, email: user.email)
        var jsonDevices: Array<DeviceJSON> = []

        for d in account.devices {
            var jsonEvents: Array<EventJSON> = []

            for e in d.events {
                jsonEvents.append(EventJSON(uuid: e.eventId, timestamp: e.timestamp, eventType: e.eventType.rawValue))
            }

            let jsonDevice: DeviceJSON = DeviceJSON(id: d.dbId, uuid: d.deviceId, name: d.name, status: d.status.rawValue, events: jsonEvents)
            jsonDevices.append(jsonDevice)
        }

        let accountJSON = AccountJSON(user: jsonUser, devices: jsonDevices)
        let encoder = JSONEncoder()
        return try? encoder.encode(accountJSON)
    }

    private func accountFromJSON(_ jsonData: Data) -> Account? {
        if let accountJSON = try? JSONDecoder().decode(AccountJSON.self, from: jsonData) {

            // Convert the codable JSON objects to real objects.
            let userJSON = accountJSON.user
            let user = User(dbId: userJSON.id, userId: userJSON.uuid, name: userJSON.name, email: userJSON.email)
            var devices: Array<Device> = []

            for dJSON in accountJSON.devices {
                var events: Array<Event> = []

                for eJSON in dJSON.events {
                    events.append(Event(eventId: eJSON.uuid, deviceId: dJSON.uuid, timestamp: eJSON.timestamp, eventType: EventType(rawValue: eJSON.eventType)!))
                }
                devices.append(Device(dbId: dJSON.id, deviceId: dJSON.uuid, name: dJSON.name, status: DeviceStatus(rawValue: dJSON.status)!, events: events))
            }

            return Account(user: user, devices: devices)
        }

        return nil
    }

    private func stateFileExists() -> Bool {
        guard let fileURL = getFileURL() else { return false }

        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    private func generateDemoAccount() -> Account {
        let demoUser = User(dbId: 5, userId: "ead003f4-83c1-483d-b40b-76574303f96e", name: "Demo User", email: "iot-stripes-demo@cmu.edu")
        let demoDevice = Device(dbId: 3, deviceId: "26130984-4221-4008-8402-01008040a050", name: "El Baby", status: .connected)
        return Account(user: demoUser, devices: [demoDevice])
    }

    // Private initializer to enorce singleton.
    private init() {}
}
