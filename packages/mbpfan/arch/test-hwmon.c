/* Exercise the real upstream fan discovery and mode controls on fake sysfs. */
#include <assert.h>
#include "mbpfan.c"
int daemonize = 0;
int verbose = 1;

int main(int argc, char **argv)
{
    assert(argc == 3);
    bool modern = strcmp(argv[2], "hwmon") == 0;
    snprintf(applesmc_path, sizeof(applesmc_path), "%s", argv[1]);
    snprintf(applesmc_fan_path, sizeof(applesmc_fan_path), "%s/fan", argv[1]);
    select_hwmon_fans();
    assert(hwmon_fans == modern);
    t_fans *head = retrieve_fans();
    int count = 0;
    set_fans_man(head);
    for (t_fans *fan = head; fan != NULL; fan = fan->next) {
        count++;
        assert(fan->fan_min_speed == 1000);
        assert(fan->fan_max_speed == 4500);
        assert(read_value(fan->fan_manual_path) == 1);
        set_fan_speed(fan, 2500);
        assert(read_value(fan->fan_output_path) == 2500);
    }
    assert(count == 3);
    set_fans_auto(head);
    for (t_fans *fan = head; fan != NULL; fan = fan->next)
        assert(read_value(fan->fan_manual_path) == (modern ? 2 : 0));
    return 0;
}
