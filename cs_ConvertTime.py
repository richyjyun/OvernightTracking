from datetime import datetime
from datetime import timedelta


basetime = datetime.fromisoformat('2021-01-01 00:00:00.000')

ts = 2472385.7126

dt = timedelta(seconds = ts)

starttime = basetime + dt