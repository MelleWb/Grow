/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct IAP_Receipt : Codable {
    
    let environment : String?
	let latest_receipt : String?
    let latest_receipt_info: [Latest_receipt_info]?
    let pending_renewal_info : [Pending_renewal_info]?
    let receipt : Receipt?
    let status : Int?

	enum CodingKeys: String, CodingKey {

        case environment = "environment"
        case latest_receipt = "latest_receipt"
        case latest_receipt_info = "latest_receipt_info"
        case pending_renewal_info = "pending_renewal_info"
        case receipt = "receipt"
        case status = "status"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		environment = try values.decodeIfPresent(String.self, forKey: .environment)
		latest_receipt = try values.decodeIfPresent(String.self, forKey: .latest_receipt)
        latest_receipt_info = try values.decodeIfPresent([Latest_receipt_info].self, forKey: .latest_receipt_info)
        pending_renewal_info = try values.decodeIfPresent([Pending_renewal_info].self, forKey: .pending_renewal_info)
        receipt = try values.decodeIfPresent(Receipt.self, forKey: .receipt)
        status = try values.decodeIfPresent(Int.self, forKey: .status)
	}

}
