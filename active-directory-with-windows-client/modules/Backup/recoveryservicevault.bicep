param location string
param vaultName string

@description('Backup policy to be used to backup VMs. Backup POlicy defines the schedule of the backup and how long to retain backup copies. By default every vault comes with a \'DefaultPolicy\' which canbe used here.')
param policyName string = 'DefaultPolicy'

@description('Times in day when backup should be triggered. e.g. 01:00 or 13:00. Must be an array, however for IaaS VMs only one value is valid. This will be used in LTR too for daily, weekly, monthly and yearly backup.')
param scheduleRunTimes array

@description('Any Valid timezone, for example:UTC, Pacific Standard Time. Refer: https://msdn.microsoft.com/en-us/library/gg154758.aspx')
param timeZone string

@description('Number of days Instant Recovery Point should be retained')
@allowed([
  1
  2
  3
  4
  5
])
param instantRpRetentionRangeInDays int


@description('Number of days you want to retain the backup')
param dailyRetentionDurationCount int

@description('Backup will run on array of Days like, Monday, Tuesday etc. Applies in Weekly retention only.')
param daysOfTheWeek array

@description('Number of weeks you want to retain the backup')
param weeklyRetentionDurationCount int

@description('Number of months you want to retain the backup')
param monthlyRetentionDurationCount int

@description('Array of Months for Yearly Retention')
param monthsOfYear array

@description('Number of years you want to retain the backup')
param yearlyRetentionDurationCount int



// Deploy Recovery Service Vault

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2024-01-01' = {
  name: vaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}




resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-01-01' = {
  name: policyName
  parent: recoveryServicesVault
  location: location
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: instantRpRetentionRangeInDays
    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: scheduleRunTimes
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
      dailySchedule: {
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: dailyRetentionDurationCount
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: daysOfTheWeek
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: weeklyRetentionDurationCount
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Daily'
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: monthlyRetentionDurationCount
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Daily'
        monthsOfYear: monthsOfYear
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: yearlyRetentionDurationCount
          durationType: 'Years'
        }
      }
      retentionPolicyType: 'LongTermRetentionPolicy'
    }
    timeZone: timeZone
  }
}

output name string = recoveryServicesVault.name
output policyId string = backupPolicy.id
