/**
 * UserDataAccessService
 * @description: Data Access Service class for the User object
 * @author: Anthony Martinez
 */
public class UserDataAccessService {
    // The following users cannot have Permission Sets assigned to them
    public static final Set<Id> queryBlacklistIdSet = new Set<Id> {
        '0050f000009iCiZAAU', /* Security User */
        '0050f000009iCiYAAU', /* Integration User */
        '0050f000009iBncAAE', /* Platform Integration User */
        '005G0000008lQp2IAE', /* System */
        '005G0000001kQyPIAU'  /* Automated Process */
    };

    /**
     * @description: Queries active users against more arbitrary filters
     * @param specifiedQueryFieldAPINameSet: queries all fields by default, or accepts a list of specified fields to include.
     * @param customSOQLFilter: Query filter. If none specified, query returns ALL active Users.
     * @return: List of active user records.
     */
    public List<User> queryActiveUserRecordsCustomFilter(List<String> specifiedQueryFieldAPINameList, String customSOQLFilter) {
        try {
            Set<Id> queryBlacklistIdSet = UserDataAccessService.queryBlacklistIdSet;

            return Database.query('SELECT ' + String.join(specifiedQueryFieldAPINameList, ',') + ' ' +
                                  'FROM User ' +
                                  'WHERE IsActive = true AND ' +
                                        'Id NOT IN :queryBlacklistIdSet ' + 
                                  (String.isNotBlank(customSOQLFilter) ? 'AND (' + customSOQLFilter + ')' : ''));
        } catch (Exception generalException) {
            throw new UserDataAccessServiceException(generalException.getMessage());        
        }
    }

    /**
     * PermissionPermissionDataAccessServiceException
     * @description: Common exception class
     */
    class UserDataAccessServiceException extends Exception {}
}