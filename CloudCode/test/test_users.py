def test_create_user(parse):
    response = parse.post('/functions/createUser', json={
        'username': 'test@test.com', 
        'password': 'password',
        'facilityId': 'ZsFlRbIPqy',
        'roleName': 'Charge Nurse',
        'assignedUnits': ['uqBzVHrDNZ', 'Hwe5xZEjOu']
    })
    
    assert response.status_code == 200
    
def test_update_user_password(parse):
    response = parse.post('/functions/updateUser', json={
        'username': 'test@test.com',
        'password': 'updated'
    })
    
    assert response.status_code == 200
    
def test_delete_user(parse):
    response = parse.post('/functions/deleteUser', json={
        'username': 'test@test.com'
    })
    
    assert response.status_code == 200