/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct In_app : Codable {
	let expires_date : String?
	let expires_date_ms : Int?
	let expires_date_pst : String?
	let in_app_ownership_type : String?
	let is_in_intro_offer_period : Bool?
	let is_trial_period : Bool?
	let original_purchase_date : String?
	let original_purchase_date_ms : Int?
	let original_purchase_date_pst : String?
	let original_transaction_id : Int?
	let product_id : String?
	let purchase_date : String?
	let purchase_date_ms : Int?
	let purchase_date_pst : String?
	let quantity : Int?
	let transaction_id : Int?
	let web_order_line_item_id : Int?

	enum CodingKeys: String, CodingKey {

		case expires_date = "expires_date"
		case expires_date_ms = "expires_date_ms"
		case expires_date_pst = "expires_date_pst"
		case in_app_ownership_type = "in_app_ownership_type"
		case is_in_intro_offer_period = "is_in_intro_offer_period"
		case is_trial_period = "is_trial_period"
		case original_purchase_date = "original_purchase_date"
		case original_purchase_date_ms = "original_purchase_date_ms"
		case original_purchase_date_pst = "original_purchase_date_pst"
		case original_transaction_id = "original_transaction_id"
		case product_id = "product_id"
		case purchase_date = "purchase_date"
		case purchase_date_ms = "purchase_date_ms"
		case purchase_date_pst = "purchase_date_pst"
		case quantity = "quantity"
		case transaction_id = "transaction_id"
		case web_order_line_item_id = "web_order_line_item_id"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		expires_date = try values.decodeIfPresent(String.self, forKey: .expires_date)
		expires_date_ms = try values.decodeIfPresent(Int.self, forKey: .expires_date_ms)
		expires_date_pst = try values.decodeIfPresent(String.self, forKey: .expires_date_pst)
		in_app_ownership_type = try values.decodeIfPresent(String.self, forKey: .in_app_ownership_type)
		is_in_intro_offer_period = try values.decodeIfPresent(Bool.self, forKey: .is_in_intro_offer_period)
		is_trial_period = try values.decodeIfPresent(Bool.self, forKey: .is_trial_period)
		original_purchase_date = try values.decodeIfPresent(String.self, forKey: .original_purchase_date)
		original_purchase_date_ms = try values.decodeIfPresent(Int.self, forKey: .original_purchase_date_ms)
		original_purchase_date_pst = try values.decodeIfPresent(String.self, forKey: .original_purchase_date_pst)
		original_transaction_id = try values.decodeIfPresent(Int.self, forKey: .original_transaction_id)
		product_id = try values.decodeIfPresent(String.self, forKey: .product_id)
		purchase_date = try values.decodeIfPresent(String.self, forKey: .purchase_date)
		purchase_date_ms = try values.decodeIfPresent(Int.self, forKey: .purchase_date_ms)
		purchase_date_pst = try values.decodeIfPresent(String.self, forKey: .purchase_date_pst)
		quantity = try values.decodeIfPresent(Int.self, forKey: .quantity)
		transaction_id = try values.decodeIfPresent(Int.self, forKey: .transaction_id)
		web_order_line_item_id = try values.decodeIfPresent(Int.self, forKey: .web_order_line_item_id)
	}

}