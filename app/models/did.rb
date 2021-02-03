# == Schema Information
#
# Table name: dids
#
#  id         :integer          not null, primary key
#  did        :string
#  doc        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_dids_on_did  (did) UNIQUE
#
class Did < ApplicationRecord
end
