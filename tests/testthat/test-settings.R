test_that("ox_settings returns and updates settings", {
  cur <- ox_settings()
  expect_true(all(c("overpass_url", "nominatim_url", "timeout") %in% names(cur)))

  old <- ox_settings(timeout = 999)
  expect_equal(ox_settings()$timeout, 999)
  ox_settings(timeout = old$timeout) # restore
  expect_equal(ox_settings()$timeout, cur$timeout)
})

test_that("ox_settings rejects unknown keys", {
  expect_error(ox_settings(nope = 1), class = "rlang_error")
})

test_that("ox_clear_cache empties the cache", {
  assign("k", 1, envir = .osmnxr_cache)
  ox_clear_cache()
  expect_length(ls(.osmnxr_cache), 0)
})
