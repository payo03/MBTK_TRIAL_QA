/**
* @Author            : payo03@solomontech.net
* @Description 		 : API Health Check
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-11      payo03@solomontech.net           Created
*/
@RestResource(UrlMapping='/api/check')
global class IF_HealthCheck {
    @HttpGet
    global static IF_HealthCheck.Result doGet() {
        return new Result();
    }

    global class Result {
        global String result{get; set;}
        global String responseDate{get; set;}
        global Result() {
            this.result = 'Health Check Success';
            this.responseDate = Datetime.now().toString();
        }
    }
}