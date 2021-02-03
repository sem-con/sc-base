# == Schema Information
#
# Table name: did_logs
#
#  id         :integer          not null, primary key
#  did        :string
#  item       :text
#  oyd_hash   :string
#  ts         :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_did_logs_on_did       (did)
#  index_did_logs_on_oyd_hash  (oyd_hash) UNIQUE
#
class DidLog < ApplicationRecord
end
