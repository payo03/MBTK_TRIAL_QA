/**
 * Created by 송찬영 on 24. 11. 03..
 */

@IsTest
private class HttpCallOutConsts_test {
    @IsTest
    static void testBehavior() {
        Assert.isNotNull(HttpCallOutConsts.SYSTEM_ERROR_CODE);
        Assert.isNotNull(HttpCallOutConsts.auth_retry_sleep);
        Assert.isNotNull(HttpCallOutConsts.CACHE_PARTITION_NAME);
        Assert.isNotNull(HttpCallOutConsts.TIMEOUT);
        Assert.isNotNull(HttpCallOutConsts.AUTH_ACCESS_TOKEN_KEY_NAME);
        Assert.isNotNull(HttpCallOutConsts.auth_info_org_cache_tts);
        Assert.isNotNull(HttpCallOutConsts.auth_retry_count);
    }
}