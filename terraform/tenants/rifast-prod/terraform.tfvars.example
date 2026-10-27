subscription_id = "b38668f6-983b-4313-ae28-03ab9d5077cc" # Mindcan Production

# Reserved from the QuotePlus production fleet's 10.200.0.0/12 block - RIFAST
# is the first customer (10.200.0.0/16). The next customer gets
# 10.201.0.0/16, and so on - keep each customer's folder's tfvars
# non-overlapping with every other customer's.
vnet_address_space        = ["10.200.0.0/16"]
aks_subnet_address_prefix = ["10.200.0.0/22"]
pe_subnet_address_prefix  = ["10.200.4.0/24"]
