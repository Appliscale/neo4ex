defmodule ExampleApp.Schema.Customer do
  defstruct [
    :index,
    :customer_id,
    :first_name,
    :last_name,
    :company,
    :city,
    :country,
    :phone_1,
    :phone_2,
    :email,
    :subscription_date,
    :website
  ]
end
