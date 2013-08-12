#!/usr/bin/env python
#
# Copyright 2012 Mike Dreves
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at:
#
#     http://opensource.org/licenses/eclipse-1.0.php
#
# By using this software in any fashion, you are agreeing to be bound
# by the terms of this license. You must not remove this notice, or any
# other, from this software. Unless required by applicable law or agreed
# to in writing, software distributed under the License is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied.
#
# @author Mike Dreves

import errno
import glob
import hashlib
import os
import re
import sys
import time
import urllib2
import webbrowser

SCALADOC_HOME = 'http://www.scala-lang.org/api/current'
SCALADOC_INDEX = SCALADOC_HOME + '/index.html'

DEFAULT_CACHE_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', 'tmp'))
OFFICIAL_SITE_CACHE_FILE = 'official_site_cache'

HREF_PATTERN = re.compile('href="([^ ><]*)"', re.I|re.U)

def Search(
    file_name, keywords, scaladoc_paths=[], cache_dir=None, cache_ttl=15):
  """Searchs for scala doc files based on keywords (package/class names).

  Args:
    file_name: File search invoked from.
    keywords: List of keywords
    scaladoc_paths: Additional paths to search for scaladocs.
    cache_dir: Directory to store index cache in.
    cache_ttl: Time (days) between refreshes of official scaladoc lib. Note,
      local caches are updated based on changes to the local index.html file.

    Search('foo.scala', ['list'])  = ['scala/collection/immutable/List.html']
    Search('foo', ['im', 'queue']) = ['scala/collection/immutable/Queue.html']
    Search('foo' ['mu', 'queue'])  = ['scala/collection/mutable/Queue.html']
  """

  if not cache_dir:
    cache_dir = DEFAULT_CACHE_DIR

  if not os.path.exists(cache_dir):
    _mkdir_p(cache_dir)

  _ClearStaleCacheEntries(cache_dir, cache_ttl)

  official_site_cache_id = os.path.join(cache_dir, OFFICIAL_SITE_CACHE_FILE)
  caches = { official_site_cache_id: SCALADOC_HOME }

  # official scaladoc
  _CheckOfficialScaladocCache(official_site_cache_id, cache_ttl)

  # if docs local to file, add them to path
  api_path = _FindLocalDocs(file_name)
  if api_path and api_path not in scaladoc_paths:
    scaladoc_paths.append(api_path)

  # additional paths
  for api_path in scaladoc_paths:
    api_path = os.path.expanduser(api_path)
    cache_id = os.path.join(
        cache_dir, 'local_' + hashlib.sha1(api_path).hexdigest())
    if _CheckLocalCache(cache_id, api_path):
      caches[cache_id] = 'file://' + api_path

  last_keyword = keywords[-1].strip('"').lower()
  prefix_pattern = '.*'  # skip main package (scala, etc)
  for keyword in keywords[:-1]:
    prefix_pattern += '/' + keyword.strip('"').lower() + '.*'

  # exact matches on last keyword (optional scala object matches)
  full_last_match = re.compile(
      prefix_pattern + '/' + last_keyword + '[$]?.html', re.I).match
  # matches that start with last keyword
  starts_with_last_match = re.compile(
      prefix_pattern + '/' + last_keyword + '.*.html', re.I).match

  matches_last = []  # exact matches on last keyword
  starts_with_last = []  # matches that start with last keyword

  for cache_file_name, url_prefix in caches.iteritems():
    with open(cache_file_name, 'r') as cache:
      for line in cache:
        m = full_last_match(line)
        if m:
          matches_last.append(url_prefix + '/' + line)
        else:
          m = starts_with_last_match(line)
          if m:
            starts_with_last.append(url_prefix + '/' + line)

  return matches_last if matches_last else starts_with_last


def OpenUrl(url):
  """Opens URL in browser."""
  webbrowser.open(url)


def _CheckOfficialScaladocCache(cache_id, cache_ttl):
  """Checks if official scaladoc cache needs updating.

  Args:
    cache_id: Local cache id to use for site.
    cache_ttl: Cache TTL.
  """

  if os.path.exists(cache_id):
    update_cache = True
    last_modified = os.path.getmtime(cache_id)
    next_refresh = time.time() - (cache_ttl * 24 * 60 * 60)
    update_cache = (last_modified < next_refresh)
  else:
    update_cache = True

  if update_cache:
    obj_entry, prev_entry = None, None
    with open(cache_id, 'w+') as cache:
      conn = urllib2.urlopen(SCALADOC_INDEX)
      for line in conn.readlines():
        for m in HREF_PATTERN.finditer(line):
          obj_entry, prev_entry = _WriteCacheEntry(
              cache, m.group(1), obj_entry, prev_entry)
      conn.close()

      # Check for any last solo object entries (have no companions)
      if obj_entry:
        cache.write(obj_entry + '\n')


def _FindLocalDocs(path):
  """Searches for API doc dirs in target dir relative to given path

  Example:
    # The following will look for '~/myproject/target/scala-xxx/api' dirs
    _FindLocalDocs('~/myproject/src/main/foo.scala')

  Args:
    path: Full path to a file that search invoked from.

  Returns:
    Full path to api docs if found (latest docs if multiple found) or None
  """
  if not path:
    return None

  while True:
    (path, tail) = os.path.split(path)
    if not tail:
      return None
    if tail == 'src':
      # found root of a project, search target for api docs
      target_path = os.path.join(path, 'target')
      if not os.path.exists(target_path):
        return None
      # search for scala-<version> dirs
      results = []
      for scala_path in glob.glob(os.path.join(target_path, 'scala-*')):
        api_path = os.path.join(scala_path, 'api')
        if os.path.exists(os.path.join(api_path, 'index.html')):
          results.append(api_path)
      if not results:
        return None
      return max(results)  # use latest scala version


def _CheckLocalCache(cache_id, api_path):
  """Checks if local cache needs updating and writes cache of docs.

  Args:
    cache_id: Cache id.
    api_path: Full path to local API docs (without index.html).
  """
  api_index = None
  if api_path:
    api_index = os.path.join(api_path, 'index.html')
  if not api_index or not os.path.exists(api_index):
    # del local cache
    if os.path.exists(cache_id):
      os.remove(cache_id)
    return False

  if os.path.exists(cache_id):
    update_cache = True
    cache_last_modified = os.path.getmtime(cache_id)
    api_last_modified = os.path.getmtime(api_path)
    update_cache = (cache_last_modified < api_last_modified)
  else:
    update_cache = True

  if update_cache:
    obj_entry, prev_entry = None, None
    with open(cache_id, 'w+') as cache:
      with open(api_index, 'r') as f:
        for line in f:
          for m in HREF_PATTERN.finditer(line):
            obj_entry, prev_entry = _WriteCacheEntry(
                cache, m.group(1), obj_entry, prev_entry)
        # Check for any last solo object entries (have no companions)
        if obj_entry:
          cache.write(obj_entry + '\n')

  return True


def _WriteCacheEntry(cache, entry, obj_entry, prev_entry):
  """Write a cache entry taking into account if scala companion was written.

  Args:
    cache: Cache to write to.
    entry: New entry read.
    obj_entry: Holds last object entry read (object entries end in $.html)
    pre_entyr: Holds prev entry read.

  Returns:
    2 tuple of new values for (obj_entry, prev_entry)
  """
  if entry.endswith('$.html'):
    if entry[:-6] != prev_entry[:-5]:
      return (entry, entry)  # don't know if companion exists yet, read next

  if obj_entry:
    if obj_entry[:-6] == entry[:-5]:
      obj_entry = None  # ok to add object, no companion

  if obj_entry:
    cache.write(obj_entry + '\n')  # solo object entry (no companion)
    obj_entry = None

  cache.write(entry + '\n')
  return (obj_entry, entry)


def _ClearStaleCacheEntries(cache_dir, cache_ttl):
  """Clears stale local cache entries from the filesytem.

  cache_ttl: Time cache can remain untouched before being deleted (days)
  """
  for cache_id in glob.glob(os.path.join(cache_dir, 'local_*')):
    last_modified = os.path.getmtime(cache_id)
    next_refresh = time.time() - (cache_ttl * 24 * 60 * 60)
    if last_modified < next_refresh:
      os.remove(cache_id)


def _mkdir_p(path):
  try:
    os.makedirs(path)
  except OSError as e:
    if e.errno == errno.EEXIST:
      pass
    else:
      raise


def main():
  if len(sys.argv) <= 1:
    return 1

  docs = Search(os.getcwd(), sys.argv[1:])
  if not docs:
    return 1

  print ''.join(docs)
  return 0


if __name__ == "__main__":
  main()
