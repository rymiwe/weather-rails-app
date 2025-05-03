# spec/support/geocoder_stubs.rb
# Geocoder test stubs for all queries used in specs
Geocoder.configure(lookup: :test)

# New York, NY
Geocoder::Lookup::Test.add_stub(
  "New York, NY", [
    {
      'latitude'     => 40.7128,
      'longitude'    => -74.0060,
      'address'      => {
        'city'    => "New York",
        'state'   => "NY",
        'country' => "United States"
      },
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
      'address'      => {
        'city'    => "London",
        'state'   => "England",
        'country' => "United Kingdom"
      },
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
      'address'      => {
        'city'    => "San Francisco",
        'state'   => "CA",
        'country' => "US"
      },
      'country_code' => "US"
    },
    {
      'latitude'     => 51.5074,
      'longitude'    => -0.1278,
      'address'      => {
        'city'    => "London",
        'state'   => "England",
        'country' => "United Kingdom"
      },
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
      'address'      => {
        'city'    => nil,
        'state'   => nil,
        'country' => nil
      },
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
      'address'      => {
        'city'    => "Portland",
        'state'   => "OR",
        'country' => "United States"
      },
      'country_code' => "US"
    }
  ]
)

# Unknown Place (returns empty array)
Geocoder::Lookup::Test.add_stub("Unknown Place", [])
Geocoder::Lookup::Test.add_stub("Invalid Query", [])

# ZIP code example
Geocoder::Lookup::Test.add_stub(
  "10001", [
    {
      'latitude'     => 40.7508,
      'longitude'    => -73.9973,
      'address'      => {
        'city'    => "New York",
        'state'   => "NY",
        'country' => "United States"
      },
      'country_code' => "US"
    }
  ]
)

# Incomplete Address example
Geocoder::Lookup::Test.add_stub(
  "Incomplete Address", [
    {
      'latitude'     => 40.7128,
      'longitude'    => -74.006,
      'address'      => {
        'city'    => nil,
        'state'   => nil,
        'country' => nil
      },
      'country_code' => 'US'
    }
  ]
)

# Malformed or malicious input (returns empty array)
Geocoder::Lookup::Test.add_stub("<script>alert('x')</script>", [])
Geocoder::Lookup::Test.add_stub("New York, NY; DROP TABLE users; --", [])
Geocoder::Lookup::Test.add_stub("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", [])
# Very long/invalid input (returns empty array)
Geocoder::Lookup::Test.add_stub("#{'A'*200}", [])
Geocoder::Lookup::Test.add_stub("#{'A'*400}", [])
Geocoder::Lookup::Test.add_stub("#{'A'*600}", [])
