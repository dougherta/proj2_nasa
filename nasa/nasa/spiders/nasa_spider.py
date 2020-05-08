from scrapy import Spider
from nasa.items import NasaItem

class NasaSpider(Spider):
    name = 'nasa_spider'
    allowed_domains = ['https://federalreporter.nih.gov/']
    start_urls = ['https://federalreporter.nih.gov/Projects/Details/?projectId=1003314&itemNum=1&totalItems=512&searchId=b850241613a74a58962c0bd1a1edd5d4&searchMode=Smart&resultType=projects&page=1&pageSize=100&sortField=ContactPiLastName&sortOrder=asc&filters=$Fy;2017$Agency;NASA&navigation=True']

    def parse(self, response):
        num_pages = int(response.xpath('//'))


        # def parse(self, response):
        # num_pages = int(response.xpath('//a[@class="trans-button page-number"]/text()').extract()[-1])

        # # Alternative way to get result page urls
        # # num_items = response.xpath('//div[@class="left-side"]/span/text()').extract_first()
        # # groups = re.search('1-(\d+) of (\d+) items', num_items)
        # # items_per_page, total_items = int(groups.group(1)), int(groups.group(2))
        # # num_pages = math.ceil(total_items/items_per_page)

        # result_urls = [f'https://www.bestbuy.com/site/all-laptops/pc-laptops/pcmcat247400050000.c?cp={i+1}&id=pcmcat247400050000' for i in range(num_pages)]

        # for url in result_urls:
        #     yield Request(url=url, callback=self.parse_results_page)