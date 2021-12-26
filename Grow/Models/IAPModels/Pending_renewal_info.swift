/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct Pending_renewal_info : Codable {
	let auto_renew_product_id : String?
	let auto_renew_status : Int?
	let expiration_intent : Int?
	let is_in_billing_retry_period : Int?
	let original_transaction_id : Int?
	let product_id : String?

	enum CodingKeys: String, CodingKey {

		case auto_renew_product_id = "auto_renew_product_id"
		case auto_renew_status = "auto_renew_status"
		case expiration_intent = "expiration_intent"
		case is_in_billing_retry_period = "is_in_billing_retry_period"
		case original_transaction_id = "original_transaction_id"
		case product_id = "product_id"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		auto_renew_product_id = try values.decodeIfPresent(String.self, forKey: .auto_renew_product_id)
		auto_renew_status = try values.decodeIfPresent(Int.self, forKey: .auto_renew_status)
		expiration_intent = try values.decodeIfPresent(Int.self, forKey: .expiration_intent)
		is_in_billing_retry_period = try values.decodeIfPresent(Int.self, forKey: .is_in_billing_retry_period)
		original_transaction_id = try values.decodeIfPresent(Int.self, forKey: .original_transaction_id)
		product_id = try values.decodeIfPresent(String.self, forKey: .product_id)
	}

}