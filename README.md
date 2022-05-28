# Base Container
Semantic Containers enable secure and traceable data exchange between 2 parties.

more infos and documentation: https://ownyourdata.eu/en/semcon

## Usage
Get the image for the base container from Dockerhub: https://hub.docker.com/r/semcon/sc-base/

Perform the following steps to start the base container:
1. Start the container  
   `docker run -d -p 3000:3000 semcon/sc-base`
2. Initialize the container  
   `curl -H "Content-Type: application/json" -d "$(< init.json)" -X POST http://localhost:3000/api/desc`
3. Write data into the container  
   `curl -H "Content-Type: application/json" -d '{"my": "data"}' -X POST http://localhost:3000/api/data`
4. Read data from container  
   `curl http://localhost:3000/api/data`
5. create image with data  
   `docker commit container_name semcon/data-example`  
   and afterwards you can start the container and access the data:  
   `docker run -d -p 3001:3000 semcon/data-example`  
   `curl http://localhost:3001/api/data`

More examples and step-by-step instructions are available in a tutorial here: https://github.com/sem-con/Tutorials/


## Improve the Base Container

Please report bugs and suggestions for new features using the [GitHub Issue-Tracker](https://github.com/sem-con/sc-base/issues) and follow the [Contributor Guidelines](https://github.com/twbs/ratchet/blob/master/CONTRIBUTING.md).

If you want to contribute, please follow these steps:

1. Fork it!
2. Create a feature branch: `git checkout -b my-new-feature`
3. Commit changes: `git commit -am 'Add some feature'`
4. Push into branch: `git push origin my-new-feature`
5. Send a Pull Request

&nbsp;    

## About  

Supported by the Federal Ministry for Climate Protection, Environment, Energy, Mobility, Innovation and Technology (Bundesministerium für Klimaschutz, Umwelt, Energie, Mobilität, Innovation und Technologie [BMK]) through FFG funding in the program “IKT der Zukunft” under [grant number 887052](https://projekte.ffg.at/projekt/4125456).

<img align="left" src="https://raw.githubusercontent.com/OwnYourData/dpv-service/main/res/210614_FFG-BM-Logoleisten_CMYK_01_BMDW-BMK-FFG_128mm.jpg" height="150">

<br clear="both" />

## Lizenz

[MIT License 2022 - OwnYourData.eu](https://raw.githubusercontent.com/sem-con/sc-base/master/LICENSE)
