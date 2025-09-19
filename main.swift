#!/usr/bin/env swift

import Foundation

// Endpoint https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT
// Response example: { "symbol": "BTCUSDT", "price": "64325.12000000" }

struct BitcoinPriceResponse: Decodable {
    let symbol: String
    let price: String
}

func getCurrentBitcoinPrice() async throws -> Double {
    let url = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT")!
    
    let (data, _) = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(BitcoinPriceResponse.self, from: data)
    
    guard let price = Double(response.price) else {
        throw NSError(domain: "BitcoinPriceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse price"])
    }
    
    return price
}

func storeBitcoinPriceToCSV(price: Double, filename: String = "bitcoin_prices.csv") throws {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let currentDate = dateFormatter.string(from: Date())
    
    let csvLine = "\(currentDate),\(price)\n"
    
    // Check if file exists to determine if we need to add header
    let fileManager = FileManager.default
    let fileExists = fileManager.fileExists(atPath: filename)
    
    if !fileExists {
        // Create file with header if it doesn't exist
        let header = "Date,Price\n"
        try header.write(toFile: filename, atomically: true, encoding: .utf8)
    }
    
    // Append the new price data
    if let fileHandle = FileHandle(forWritingAtPath: filename) {
        defer { fileHandle.closeFile() }
        fileHandle.seekToEndOfFile()
        fileHandle.write(csvLine.data(using: .utf8)!)
    } else {
        throw NSError(domain: "FileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not open file for writing"])
    }
}

func getAndStoreBitcoinPrice() async throws {
    let price = try await getCurrentBitcoinPrice()
    try storeBitcoinPriceToCSV(price: price)
    print("Bitcoin price $\(price) stored to CSV file")
}

try await getAndStoreBitcoinPrice()