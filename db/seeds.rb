# Replace <your gmail name> with your gmail name below.

Community.create!([
  {name: "My Community", abbrv: "MC"}
])

Household.create!([
  {unit_num: "0", community_id: 1, name: "Admins", deactivated_at: nil}
])

User.create!([
  {email: "kenatsun@gmail.com", google_email: "kenatsun@gmail.com", first_name: "Alice", last_name: "Admin", mobile_phone: "17345551212", household_id: 1, admin: true}
])



