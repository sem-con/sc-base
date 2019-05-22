# == Schema Information
#
# Table name: billings
#
#  id                    :integer          not null, primary key
#  address_path          :string
#  buyer                 :string
#  buyer_address         :string
#  buyer_info            :text
#  buyer_signature       :text
#  offer_info            :text
#  offer_price           :float
#  offer_timestamp       :datetime
#  payment_address       :string
#  payment_method        :string
#  payment_price         :float
#  payment_timestamp     :datetime
#  request               :text
#  seller                :string
#  seller_signature      :text
#  transaction_hash      :string
#  transaction_timestamp :string
#  uid                   :string
#  usage_policy          :text
#  valid_until           :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  buyer_pubkey_id       :string
#  seller_pubkey_id      :string
#

class Billing < ApplicationRecord
end
