#!/usr/bin/env python
# coding=utf-8
import os
import sys
import inotifyx
from inotifyx import binding
import subprocess
from datetime import datetime, timedelta
import simplejson as json


PROJECT_PATH = os.getcwd()
PROJECT_SETTINGS = os.path.join(PROJECT_PATH, 'package.json')
SOURCE_PATH = os.path.join(PROJECT_PATH, 'source')
TEMPLATE_PATH = os.path.join(PROJECT_PATH, 'views')
TIME_INTERVAL = timedelta(seconds=5)
EXTENSIONS = ['d', 'dt']


class DUB:
	DUB_CMD = 'dub'
	DUB_CMD_BUILD = [DUB_CMD, 'build']
	DUB_CMD_RUN = [DUB_CMD, 'run']

	def __init__(self):
		self.project_name = os.path.basename(PROJECT_PATH)
		if os.path.exists(PROJECT_SETTINGS):
			with open(PROJECT_SETTINGS, 'r') as settings_file:
				settings = json.loads(settings_file.read())
				self.project_name = settings.get('name')
		self.process = None

	def build(self):
		process = subprocess.Popen(self.DUB_CMD_BUILD)
		process.wait()
		if process.returncode:
			return False
		return True

	def start(self):
		file_run = os.path.join(PROJECT_PATH, self.project_name)
		self.process = subprocess.Popen(file_run)
		print "Run process PID: %s" % self.process.pid

	def stop(self):
		if self.process:
			self.process.kill()
			print "Kill process PID: %s" % self.process.pid
			self.process = None
			return True
		else:
			print "Not found process"

	def restart(self, rebuild=False):
		if self.stop():
			if rebuild:
				if self.build():
					self.start()
				else:
					print "Error build"
					#sys.exit(0)
			else:
				self.start()


if __name__ == '__main__':
	dub = DUB()

	if not dub.build():
		sys.exit(1)

	try:
		dub.start()
		fd = inotifyx.init()
		inotifyx.add_watch(fd, SOURCE_PATH, binding.IN_MODIFY)
		inotifyx.add_watch(fd, TEMPLATE_PATH, binding.IN_MODIFY)

		start_time = datetime.now()
		while True:
			events = inotifyx.get_events(fd)
			end_time = datetime.now()
			isrestart = False
			if (end_time - start_time) > TIME_INTERVAL:
				for event in events:
					if event.name and event.name.split(".")[-1] in EXTENSIONS:
						isrestart = True
			start_time = end_time
			if isrestart:
				dub.restart(True)

	except KeyboardInterrupt:
		dub.stop()
	finally:
		dub.stop()
