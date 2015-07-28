def test_get_worksheet(parse):
    response = parse.post('/functions/getWorksheet', json={
		'dateString': '2015-07-20',
		'facilityId': 'ZsFlRbIPqy',
		'time': 54000
    })
    
    assert response.status_code == 200