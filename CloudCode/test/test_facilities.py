def test_get_facility(parse):
    assert parse.post('/functions/getFacility', json={'facilityId': 'ZsFlRbIPqy'}).status_code == 200