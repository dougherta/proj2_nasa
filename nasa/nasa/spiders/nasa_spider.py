from scrapy import Spider, Request
from nasa.items import NasaItem

class NasaSpider(Spider):
    name = 'nasa_spider'
    allowed_domains = ['federalreporter.nih.gov']
    # start url for 2017 NASA research funding
    # start_urls = ['https://federalreporter.nih.gov/Projects/Details/?projectId=1003314&itemNum=1&totalItems=512&searchId=b850241613a74a58962c0bd1a1edd5d4&searchMode=Smart&resultType=projects&page=1&pageSize=100&sortField=ContactPiLastName&sortOrder=asc&filters=$Fy;2017$Agency;NASA&navigation=True']
    # start url for 2016 NASA research funding
    # start_urls = ['https://federalreporter.nih.gov/Projects/Details/?projectId=907369&ItemNum=1&totalItems=1385&searchId=b850241613a74a58962c0bd1a1edd5d4&searchMode=Smart&resultType=projects&page=1&pageSize=100&sortField=ContactPiLastName&sortOrder=asc&filters=$Fy;2016$Agency;NASA&navigation=True']
    # start url for 2016/17 all other Federal Reporter Organizations including HHS, NSF, USDA, VA, DOD, EPA, ED
    # start_urls = ['https://federalreporter.nih.gov/Projects/Details/?projectId=338965&ItemNum=1&totalItems=177651&searchId=fa933fad51474b5096bbd780c2f493c2&searchMode=Smart&resultType=projects&page=1&pageSize=100&sortField=Fy&sortOrder=asc&filters=$Agency;HHS;NIH;NCI;NIAID;NIGMS;NHLBI;NIDDK;NINDS;NIA;NIMH;NICHD;NIDA;NEI;NIEHS;NIAMS;NIAAA;NIDCD;NIBIB;NIDCR;OD;NIMHD;NHGRI;NCATS;NINR;NCCIH;FIC;NLM;CLC;CIT;NCRR;ALLCDC;COGH;NCHHSTP;NIOSH;NCCDPHP;NCIPC;NCBDD;CDC;NCEH;NCIRD;ATSDR;COTPER;NCHS;ODCDC;CID;NCHM;OGDP;OWCD;FDA;AHRQ;NIDILRR;ACF;NSF;USDA;NIFA;ARS;FS;VA;DOD;CDMRP;DVBIC;CNRM;CCCRP;ED;IES;NCER;NCSER;EPA&navigation=True']        
    # start url for 2014/15 NASA research funding
    # start_urls = ['https://federalreporter.nih.gov/Projects/Details/?projectId=797785&ItemNum=1&totalItems=3404&searchId=a74208183fec4fe787066ed6ee80effa&searchMode=Smart&resultType=projects&page=1&pageSize=100&sortField=ContactPiLastName&sortOrder=asc&filters=&navigation=True']

    # start url for 2008-13 NASA research funding
    start_urls = ['https://federalreporter.nih.gov/Projects/Details/?projectId=90940&ItemNum=1&totalItems=10937&searchId=145893c58e3e4dd697440e3edc8807aa&searchMode=Smart&resultType=projects&page=1&pageSize=100&sortField=Fy&sortOrder=asc&filters=$Fy;2013;2012;2011;2010;2009;2008&navigation=True']



    def parse(self, response):
        agency = response.xpath('//span[@id="agencyCode"]/text()').extract_first()
        proj_num = response.xpath('//span[@class="item-detail header-project-number"]/text()').extract_first().strip() # xpath for NASA only search
        # proj_num = response.xpath('//a[@class="item-detail header-project-number"]/span/text()').extract_first().strip() # xpath for all agencies search
        proj_lead = response.xpath('//span[@class="item-detail"]/text()').extract_first().strip()
        
        # if organization is empty make none
        try:
            organization = response.xpath('//div[@class="col-md-4 col-sm-4"]/span/text()').extract_first().strip()
        except:
            organization = None

        title = response.xpath('//h2[@class="record-title"]/text()').extract_first()
        abstract = response.xpath('//*[@id="details-box"]/div[2]/div[3]/div[2]/div/div[2]/div/div[2]/span/text()').get()
        proj_terms = response.xpath('//*[@id="details-box"]/div[2]/div[3]/div[2]/div/div[2]/div/div[4]/span/text()').get()
        city = response.xpath('//*[@id="details-box"]/div[2]/div[3]/div[2]/div/div[4]/div[1]/span[2]/text()').extract_first().strip()
        state = response.xpath('//*[@id="details-box"]/div[2]/div[3]/div[2]/div/div[4]/div[2]/span[1]/text()').extract_first().strip()
        country = response.xpath('//*[@id="details-box"]/div[2]/div[3]/div[2]/div/div[4]/div[1]/span[3]/text()').extract_first().strip()
        
        # if congressional district empty make none
        try:
            cong_dist = int(response.xpath('//*[@id="details-box"]/div[2]/div[3]/div[2]/div/div[4]/div[2]/span[2]/text()').extract_first().strip())
        except:
            cong_dist = None

        fy = int(response.xpath('//div[@class="det-sec col-md-5 col-sm-4 col-xs-12"]/span/text()').extract_first().strip())
        award_notice = response.xpath('//div[@class="det-sec col-md-5 col-sm-4 col-xs-12"]/span[2]/text()').getall()
        proj_start = response.xpath('//div[@class="det-sec col-md-4 col-sm-4 col-xs-12"]/span[2]/text()').getall()
        proj_end = response.xpath('//div[@class="det-sec col-md-3 col-sm-4 col-xs-12"]/span[2]/text()').getall()
        
        # try/except for fiscal year total cost. If funding information not available except.
        try:
            fy_tot_cost = response.xpath('//div[@class="det-sec col-md-6 col-sm-8 col-xs-12"]/table[@id="proj-funding"]/tbody/tr[2]/td[3]/text()').extract_first().strip()
        except:
            fy_tot_cost = response.xpath('//div[@class="det-sec col-md-12 col-sm-12 col-xs-12"]/p/text()').extract_first()


        item = NasaItem()
        item['agency'] = agency
        item['proj_num'] = proj_num
        item['proj_lead'] = proj_lead
        item['organization'] = organization
        item['title'] = title
        item['abstract'] = abstract
        item['proj_terms'] = proj_terms
        item['city'] = city
        item['state'] = state
        item['country'] = country
        item['cong_dist'] = cong_dist
        item['fy'] = fy
        item['award_notice'] = award_notice
        item['proj_start'] = proj_start
        item['proj_end'] = proj_end
        item['fy_tot_cost'] = fy_tot_cost

        yield item

        next_exists = response.xpath('//a[@id="tr-nav-arrow"]/@href').extract_first()

        if next_exists:
            next_exists = 'https://federalreporter.nih.gov/' + next_exists

            yield Request(url=next_exists, callback=self.parse)