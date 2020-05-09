# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# https://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class NasaItem(scrapy.Item):
    # define the fields for your item here like:
    agency = scrapy.Field()
    proj_num = scrapy.Field()
    proj_lead = scrapy.Field()
    organization = scrapy.Field()
    title = scrapy.Field()
    abstract = scrapy.Field()
    proj_terms = scrapy.Field()
    city = scrapy.Field()
    state = scrapy.Field()
    country = scrapy.Field()
    cong_dist = scrapy.Field()
    fy = scrapy.Field()
    award_notice = scrapy.Field()
    proj_start = scrapy.Field()
    proj_end = scrapy.Field()
    fy_tot_cost = scrapy.Field()

