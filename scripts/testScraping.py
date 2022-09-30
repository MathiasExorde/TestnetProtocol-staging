import snscrape.modules
import datetime as dt
from datetime import timezone
import pandas as pd
import pytz

keyword = "Bitcoin"

datenow = dt.datetime.now(pytz.timezone('UTC'))
time_delta = dt.timedelta(minutes=380) # dt.timedelta() #à remplir
search_date =  datenow-time_delta#à remplir
pd_dataframe = None

for i, _post in enumerate(snscrape.modules.twitter.TwitterSearchScraper('(about:{}) since_time:{}'.format(keyword, int(search_date.timestamp()))).get_items()):
	

	post = _post.__dict__

	tr_post = dict()

	tr_post["internal_id"] = post["id"]
	tr_post["internal_parent_id"] = post["inReplyToTweetId"] #post["referenced_tweets"][0]["id"] if "referenced_tweets" in post and len(post["referenced_tweet"]) != 0 and post["referenced_tweets"][0]["id"] != None else 0

	tr_post["content"] = post["content"]
	tr_post["hashtags"] = post["hashtags"]
	tr_post["keyword"] = keyword
	tr_post["domainName"] = "twitter.com"
	tr_post["url"] = "https://twitter.com/ExordeLabs/status/{}".format(post["id"])
	tr_post["author"] = post["user"].displayname
	tr_post["authorLocation"] = post["user"].location
	tr_post["creationDateTime"] = post["date"] #parse(post["date"]).replace(tzinfo=pytz.timezone('UTC'))
	tr_post["lang"] = post["lang"]
	tr_post["title"] = '' #post["title"] if "title" in post else None

	print(tr_post)