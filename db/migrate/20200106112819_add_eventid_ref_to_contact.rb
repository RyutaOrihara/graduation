class AddEventidRefToContact < ActiveRecord::Migration[5.2]
  def change
    add_reference :contacts, :event, foreign_key: true
  end
end
