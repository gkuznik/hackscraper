sources = [
    "https://hack.tum.de",
    "https://hackfest.tech/",
    "https://ethmunich.de/",
    "https://hack.startmunich.de/events/rtsh",
    "https://makeathon.tum-ai.com/",
    "https://munihac.de",
    "https://www.cassini.eu/hackathons/",
    # 403 "https://eudis-hackathon.eu/",
    "https://imprs-astro-hackathon.de/",
    "https://www.pushquantum.tech/pq-hackathon",
    "https://hackathon.radiology.bayer.com/",
    "https://www.hackbay.de/",
]

aggregators = {
    "https://roboinnovate.mirmi.tum.de/",
    "https://opensource.construction/#events",
    "https://germantechjobs.de/events",
    "https://www.bayern-innovativ.de/events-termine/",
    "https://www.munich-urban-colab.de/events",
    "https://www.mdsi.tum.de/mdsi/aktuelles/veranstaltungen/",
    "https://veranstaltungen.muenchen.de/rit/",
    "https://www.tum-blockchain.com/events-category/hackathon",
}

for s in sources:
    print("(get_hackathon,", "'" + s + "')", end=",\n")
