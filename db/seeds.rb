# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

User.find_or_create_by!(username: "utente") do |user|
  user.password = "pAssword1234567"
  user.password_confirmation = "pAssword1234567"
  user.first_name = "Davo"
  user.last_name = "Davosky"
  user.gender = "M"
  user.region = "FVG"
  user.province = "FVG"
  user.category = "CGIL"
  user.admin = true
  user.manager = false
  user.regular = false
end
