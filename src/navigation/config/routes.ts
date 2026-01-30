import Signin from '@features/auth/sign-in'
import Signup from '@features/auth/sign-up'
import { createEnum } from './type'

/**
/**
 * Routes for screens
 */
export const ROUTES = createEnum({
  Login: 'Login'
})

/**
/**
 * Common screens
 */

export const commonScreens = {}

/**
 * Screens when user logged in
 */
export const userScreens = {}

/**
 * Screens user when user not logged in
 *
 */
export const notLoggedInScreens = {
  Signin: Signin,
  Signup: Signup
}

/**
 * Modal
 */
export const notLoggedInModalSlides = {}
export const userModalSlides = {}
export const commonModalSlides = {}

/**
 * Bottom Tabs
 */
export const bottomTabScreens = []

/**
 * Dev screens
 */

export const devScreens = {}
