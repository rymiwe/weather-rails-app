# spec/support/geocoder_stubs.rb
# Geocoder test stubs for all queries used in specs
Geocoder.configure(lookup: :test)

# New York, NY
Geocoder::Lookup::Test.add_stub(
  "New York, NY", [
    {
      'latitude'     => 40.7128,
      'longitude'    => -74.0060,
      'address'      => "New York, NY, USA",
      'city'         => "New York",
      'state'        => "NY",
      'country'      => "US",
      'country_code' => "US"
    }
  ]
)

# London
Geocoder::Lookup::Test.add_stub(
  "London", [
    {
      'latitude'     => 51.5074,
      'longitude'    => -0.1278,
      'address'      => "London, England, United Kingdom",
      'city'         => "London",
      'state'        => "England",
      'country'      => "United Kingdom",
      'country_code' => "GB"
    }
  ]
)

# Ambiguous (US result first, as expected by test)
Geocoder::Lookup::Test.add_stub(
  "Ambiguous", [
    {
      'latitude'     => 37.7749,
      'longitude'    => -122.4194,
      'address'      => "San Francisco, CA, USA",
      'city'         => "San Francisco",
      'state'        => "CA",
      'country'      => "US",
      'country_code' => "US"
    },
    {
      'latitude'     => 51.5074,
      'longitude'    => -0.1278,
      'address'      => "London, England, United Kingdom",
      'city'         => "London",
      'state'        => "England",
      'country'      => "United Kingdom",
      'country_code' => "GB"
    }
  ]
)

# Nowhere (arbitrary coordinates, no city/state, but address present)
Geocoder::Lookup::Test.add_stub(
  "Nowhere", [
    {
      'latitude'     => 10.0,
      'longitude'    => 10.0,
      'address'      => "Nowhere",
      'city'         => nil,
      'state'        => nil,
      'country'      => nil,
      'country_code' => 'US'
    }
  ]
)

# Portland, OR
Geocoder::Lookup::Test.add_stub(
  "Portland, OR", [
    {
      'latitude'     => 45.5152,
      'longitude'    => -122.6784,
      'address'      => "Portland, OR, USA",
      'city'         => "Portland",
      'state'        => "OR",
      'country'      => "US",
      'country_code' => "US"
    }
  ]
)

# Unknown Place (returns empty array)
Geocoder::Lookup::Test.add_stub("Unknown Place", [])

# Malformed or malicious input (returns empty array)
Geocoder::Lookup::Test.add_stub("<script>alert('x')</script>", [])
Geocoder::Lookup::Test.add_stub("New York, NY; DROP TABLE users; --", [])
Geocoder::Lookup::Test.add_stub("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", [])
# Very long/invalid input (returns empty array)
Geocoder::Lookup::Test.add_stub("#{'A'*200}", [])
Geocoder::Lookup::Test.add_stub("#{'A'*400}", [])
Geocoder::Lookup::Test.add_stub("#{'A'*600}", [])
