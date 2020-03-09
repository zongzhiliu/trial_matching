import datetime

def today_stamp():
    return datetime.date.today().isoformat().replace('-', '')

def now_stamp():
    return datetime.datetime.now().isoformat().split('.')[0].replace('-', '').replace(':', '')

### tests
def test_today_stamp():
    print (today_stamp())

def test_now_stamp():
    print (now_stamp())
