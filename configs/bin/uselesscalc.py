#!/bin/python3
import multiprocessing
import hashlib
import os
import time
from datetime import datetime
import logging

now = datetime.now() # current date and time
filename = now.strftime("%Y-%m-%d__%H-%M-%S")
logging.basicConfig(filename=f"{os.path.expanduser('~')}/{filename}.log", level=logging.INFO)


top_output = ''.join(os.popen('top -bn 1 -i').readlines())

globalstart = time.time()

cores = multiprocessing.cpu_count()

def calc(q: multiprocessing.Queue):
    pid = os.getpid()
    while True:
        try:
            hexhs = q.get(timeout=0.01)
            start = time.time()
            res = (hexhs ** (hexhs >> 242)) % 65536
            logging.debug(f"{multiprocessing.current_process()}\nres: {res}\nts: {time.time()-start}\n")
        except BaseException as exc:
            logging.debug(f"Closing {multiprocessing.current_process()}")
            break

st = os.uname().nodename # fest aber beliebig
h = hashlib.new('sha256')
h.update(str(st).encode())
hs = f"0x{h.hexdigest()}"
hexhs = int(hs,0)

que = multiprocessing.Queue()
for i in range(1024):
    que.put(hexhs + i)


threads = [multiprocessing.Process(target=calc, args=(que,)) for _ in range(cores)]
for t in threads:
    t.start()

for t in threads:
    t.join()


timetotal = time.time() - globalstart
logging.info(f"Time: {timetotal}\n\n----\n")

time.sleep(5)
logging.info(f"<top -bn 1 -i>\n{top_output}")

#   # gives a single float value
#   logging.info(f"CPU use: {psutil.cpu_percent()}%")
#   time.sleep(5)
#   # you can have the percentage of used RAM
#   logging.info(f"RAM use: {psutil.virtual_memory().percent}%")


