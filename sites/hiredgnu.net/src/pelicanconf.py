AUTHOR = 'Ryan Tracey'
SITENAME = 'HiredGnu'
SITEURL = ""

PATH = "content"

TIMEZONE = 'Europe/Berlin'

DEFAULT_LANG = 'en'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

# Blogroll
LINKS = (
    ("Ryan's Substack", "https://hiredgnu.substack.com/"),
)

# Social widget
SOCIAL = (
    ("BlueSky UA View", "https://bsky.app/profile/bsky.one/feed/ukrainian-view"),
    ("BlueSky UA Fund Raising", "https://bsky.app/profile/dovgonosyk.bsky.social/feed/aaaapknzigxfi"),
)


# DIRECT_TEMPLATES = ['index']

# Uncomment following line if you want document-relative URLs when developing
RELATIVE_URLS = True

THEME = '../themes/pelican-simplegrey'

# pagination

# number of articles on a page
DEFAULT_PAGINATION = 6

# articles on page per type. None = default
PAGINATED_TEMPLATES = {'index': 0, 'tag': None, 'category': None, 'author': None}

STATIC_PATHS = ['images', 'pdfs']

EXTRA_PATH_METADATA = {
    'images/favicon.ico': {'path': 'favicon.ico'},
}
