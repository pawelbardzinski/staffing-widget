def test_get_worksheet(parse):
    response = parse.post('/functions/instanceTargetReport', params={
		'thisMonthString': '2015-06'
    })
    
    assert response.status_code == 200