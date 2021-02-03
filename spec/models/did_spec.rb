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
require 'rails_helper'

RSpec.describe Did, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
