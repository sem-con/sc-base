# == Schema Information
#
# Table name: stores
#
#  id         :integer          not null, primary key
#  dri        :string
#  item       :text
#  key        :string
#  mime_type  :string
#  schema_dri :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  prov_id    :integer
#
# Indexes
#
#  index_stores_on_dri         (dri)
#  index_stores_on_schema_dri  (schema_dri)
#

class Store < ApplicationRecord
end
