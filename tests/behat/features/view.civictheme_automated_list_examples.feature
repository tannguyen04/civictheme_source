@p0 @civictheme @civictheme_automated_list
Feature: CivicTheme listing renders on views pages with filters

  Ensure that CivicTheme listing component can be used on the views
  pages (without paragraph) and that exposed filters work when attached
  to the view and exposed as a block.

  The views already exist as configuration.

  Background:
    Given "civictheme_topics" terms:
      | name           |
      | [TEST] Topic 1 |
      | [TEST] Topic 2 |
      | [TEST] Topic 3 |
      | [TEST] Topic 4 |

    And "civictheme_page" content:
      | title          | created                | status | field_c_n_topics                               |
      | [TEST] Page 1  | [relative:-1 minutes]  | 1      | [TEST] Topic 1, [TEST] Topic 2, [TEST] Topic 3 |
      | [TEST] Page 2  | [relative:-2 minutes]  | 1      | [TEST] Topic 1, [TEST] Topic 2, [TEST] Topic 3 |
      | [TEST] Page 3  | [relative:-3 minutes]  | 1      | [TEST] Topic 1                                 |
      | [TEST] Page 4  | [relative:-4 minutes]  | 1      | [TEST] Topic 1                                 |
      | [TEST] Page 5  | [relative:-5 minutes]  | 1      | [TEST] Topic 2                                 |
      | [TEST] Page 6  | [relative:-6 minutes]  | 1      | [TEST] Topic 2                                 |
      | [TEST] Page 7  | [relative:-7 minutes]  | 1      | [TEST] Topic 3                                 |
      | [TEST] Page 8  | [relative:-8 minutes]  | 1      | [TEST] Topic 3                                 |
      | [TEST] Page 9  | [relative:-9 minutes]  | 1      |                                                |
      | [TEST] Page 10 | [relative:-10 minutes] | 1      |                                                |
      | [TEST] Page 11 | [relative:-11 minutes] | 0      |                                                |
      | [TEST] Page 12 | [relative:-12 minutes] | 0      | [TEST] Topic 3                                 |
      | [TEST] Page 13 | [relative:-13 minutes] | 1      |                                                |
      | [TEST] Page 14 | [relative:-14 minutes] | 1      |                                                |
      | [TEST] Page 15 | [relative:-15 minutes] | 1      |                                                |

  @api @testmode
  Scenario: Listing example - no filters
    Given I am an anonymous user
    When I go to "civictheme-no-sidebar/listing-no-filter"
    Then the response status code should be 200

    And I should not see an ".ct-list__filters" element

    And I should see the text "[TEST] Page 1"
    And I should see the text "[TEST] Page 2"
    And I should see the text "[TEST] Page 3"
    And I should see the text "[TEST] Page 4"
    And I should see the text "[TEST] Page 5"
    And I should see the text "[TEST] Page 6"
    And I should see the text "[TEST] Page 7"
    And I should see the text "[TEST] Page 8"
    And I should see the text "[TEST] Page 9"
    And I should see the text "[TEST] Page 10"
    # Not published pages.
    And I should not see the text "[TEST] Page 11"
    And I should not see the text "[TEST] Page 12"
    # Published and should be on the first page.
    And I should see the text "[TEST] Page 13"
    And I should see the text "[TEST] Page 14"
    # Published page, but on the next page.
    And I should not see the text "[TEST] Page 15"

    # Pager should be visible.
    And I should see a ".ct-list__pager" element

  # Uncomment when filters are fixed.
  @api @testmode
  Scenario Outline: Listing example - Filters
    Given I am an anonymous user
    When I go to "<path>"
    Then the response status code should be 200

    And I should see "[TEST] Topic 1" in the "<filter_element>" element
    And I should see "[TEST] Topic 2" in the "<filter_element>" element
    And I should see "[TEST] Topic 3" in the "<filter_element>" element
    And I should see "[TEST] Topic 4" in the "<filter_element>" element

    And I should see the text "[TEST] Page 1"
    And I should see the text "[TEST] Page 2"
    And I should see the text "[TEST] Page 3"
    And I should see the text "[TEST] Page 4"
    And I should see the text "[TEST] Page 5"
    And I should see the text "[TEST] Page 6"
    And I should see the text "[TEST] Page 7"
    And I should see the text "[TEST] Page 8"
    And I should see the text "[TEST] Page 9"
    And I should see the text "[TEST] Page 10"
     # Not published pages.
    And I should not see the text "[TEST] Page 11"
    And I should not see the text "[TEST] Page 12"
     # Published and should be on the first page.
    And I should see the text "[TEST] Page 13"
    And I should see the text "[TEST] Page 14"
     # Published page, but on the next page.
    And I should not see the text "[TEST] Page 15"

     # Pager should be visible.
    And I should see a ".ct-pager" element

    Examples:
      | path                                                                 | filter_element    |
      | civictheme-no-sidebar/listing-one-filter-single-select               | .ct-single-filter |
      | civictheme-no-sidebar/listing-one-filter-single-select-exposed-block | .ct-single-filter |
      | civictheme-no-sidebar/listing-one-filter-multi-select                | .ct-single-filter |
      | civictheme-no-sidebar/listing-one-filter-multi-select-exposed-block  | .ct-single-filter |
      | civictheme-no-sidebar/listing-multiple-filters                       | .ct-group-filter  |
      | civictheme-no-sidebar/listing-multiple-filters-exposed-block         | .ct-group-filter  |

  @api @testmode @skipped
  # Fix later - the step definition assertion itself fails.
  # Scenario Outline: Listing example - One filter - Single
  #   Given I am an anonymous user
  #   When I go to "<path>"
  #   Then the response status code should be 200
  #
  #   When I select the radio button "[TEST] Topic 1"
  #   And I press "Apply"
  #
  #   Then I should see the text "[TEST] Page 1"
  #   And I should see the text "[TEST] Page 2"
  #   And I should see the text "[TEST] Page 3"
  #   And I should see the text "[TEST] Page 4"
  #   And I should not see the text "[TEST] Page 5"
  #   And I should not see the text "[TEST] Page 6"
  #   And I should not see the text "[TEST] Page 7"
  #   And I should not see the text "[TEST] Page 8"
  #   And I should not see the text "[TEST] Page 9"
  #   And I should not see the text "[TEST] Page 10"
  #   And I should not see the text "[TEST] Page 11"
  #   And I should not see the text "[TEST] Page 12"
  #   And I should not see the text "[TEST] Page 13"
  #   And I should not see the text "[TEST] Page 14"
  #   And I should not see the text "[TEST] Page 15"
  #
  #   Examples:
  #     | path                                                                 |
  #     | civictheme-no-sidebar/listing-one-filter-single-select               |
  #     | civictheme-no-sidebar/listing-one-filter-single-select-exposed-block |

  @api @testmode
  Scenario Outline: Listing example - One filter - Multi
    Given I am an anonymous user
    When I go to "<path>"
    Then the response status code should be 200

    When I check the box "[TEST] Topic 1"
    And I check the box "[TEST] Topic 2"
    And I press "Apply"

    Then I should see the text "[TEST] Page 1"
    And I should see the text "[TEST] Page 2"
    And I should see the text "[TEST] Page 3"
    And I should see the text "[TEST] Page 4"
    And I should see the text "[TEST] Page 5"
    And I should see the text "[TEST] Page 6"
    And I should not see the text "[TEST] Page 7"
    And I should not see the text "[TEST] Page 8"
    And I should not see the text "[TEST] Page 9"
    And I should not see the text "[TEST] Page 10"
    And I should not see the text "[TEST] Page 11"
    And I should not see the text "[TEST] Page 12"
    And I should not see the text "[TEST] Page 13"
    And I should not see the text "[TEST] Page 14"
    And I should not see the text "[TEST] Page 15"
    # @todo Remove once https://www.drupal.org/project/drupal/issues/2900248 is resolved.
    And the cache has been cleared

    Examples:
      | path                                                                |
      | civictheme-no-sidebar/listing-one-filter-multi-select               |
      | civictheme-no-sidebar/listing-one-filter-multi-select-exposed-block |

  @api @testmode
  Scenario Outline: Listing example - Multiple filters
    Given I am an anonymous user
    When I go to "<path>"
    Then the response status code should be 200

    When I select "[TEST] Topic 1" from "topic_id[]"
    And I additionally select "[TEST] Topic 2" from "topic_id[]"
    And I press "Apply"

    Then I should see the text "[TEST] Page 1"
    And I should see the text "[TEST] Page 2"
    And I should see the text "[TEST] Page 3"
    And I should see the text "[TEST] Page 4"
    And I should see the text "[TEST] Page 5"
    And I should see the text "[TEST] Page 6"
    And I should not see the text "[TEST] Page 7"
    And I should not see the text "[TEST] Page 8"
    And I should not see the text "[TEST] Page 9"
    And I should not see the text "[TEST] Page 10"
    And I should not see the text "[TEST] Page 11"
    And I should not see the text "[TEST] Page 12"
    And I should not see the text "[TEST] Page 13"
    And I should not see the text "[TEST] Page 14"
    And I should not see the text "[TEST] Page 15"

    Examples:
      | path                                           |
      | civictheme-no-sidebar/listing-multiple-filters |
      # Disabled test below as it fails in CI with "An illegal choice
      # has been detected. Please contact the site administrator." message.
      # Need to investigate.
      # | civictheme-no-sidebar/listing-multiple-filters-exposed-block |

  @api @testmode
  Scenario: Listing example - Title filter
    Given I am an anonymous user
    When I go to "civictheme-no-sidebar/listing-multiple-filters"
    Then the response status code should be 200
    And I see field "Title"
    And should see an "input[name='title']" element
    And should not see an "input[name='title'].required" element
