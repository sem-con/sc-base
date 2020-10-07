# == Schema Information
#
# Table name: provenances
#
#  id             :integer          not null, primary key
#  endTime        :datetime
#  input_hash     :string
#  prov           :text
#  receipt_hash   :string
#  revocation_key :string
#  scope          :text
#  startTime      :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Provenance < ApplicationRecord
end
