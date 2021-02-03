# == Schema Information
#
# Table name: did_sessions
#
#  id                   :integer          not null, primary key
#  challenge            :string
#  session              :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  oauth_application_id :string
#
require 'rails_helper'

RSpec.describe DidSession, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
