import React, { useEffect } from 'react';
import {
  requireNativeComponent,
  NativeModules,
  StyleSheet,
  ViewStyle,
  NativeSyntheticEvent,
} from 'react-native';

const { SimulaAdSDK } = NativeModules;

export interface Message {
  role: string;
  content: string;
}

export interface MiniGameTheme {
  backgroundColor?: string;
  headerColor?: string;
  borderColor?: string;
  titleFont?: string;
  secondaryFont?: string;
  titleFontColor?: string;
  secondaryFontColor?: string;
  iconCornerRadius?: number;
  accentColor?: string;
  playableHeight?: string;
  playableBorderColor?: string;
}

export interface MiniGameProviderProps {
  apiKey: string;
  primaryUserID?: string;
  hasPrivacyConsent?: boolean;
  devMode?: boolean;
  appDomain?: string;
  children?: React.ReactNode;
}

export const MiniGameProvider: React.FC<MiniGameProviderProps> = ({
  apiKey,
  primaryUserID = null,
  hasPrivacyConsent = true,
  devMode = false,
  appDomain = 'coolaigames.com',
  children,
}) => {
  useEffect(() => {
    if (SimulaAdSDK) {
      SimulaAdSDK.configure(
        apiKey,
        primaryUserID,
        hasPrivacyConsent,
        devMode,
        appDomain
      );
    } else {
      console.warn('[SimulaAdSDK] Native module SimulaAdSDK is not available.');
    }
  }, [apiKey, primaryUserID, hasPrivacyConsent, devMode, appDomain]);

  return <>{children}</>;
};

interface NativeMiniGameMenuProps {
  isOpen: boolean;
  charName: string;
  charID: string;
  charImage: string;
  messages?: Message[];
  charDesc?: string;
  convId?: string;
  entryPoint?: string;
  maxGamesToShow?: number;
  theme?: MiniGameTheme;
  delegateChar?: boolean;
  showBanner?: boolean;
  
  onGameOpen?: (e: NativeSyntheticEvent<{ gameName: string, description: string }>) => void;
  onGameClose?: (e: NativeSyntheticEvent<{ gameName: string }>) => void;
  onImpression?: (e: NativeSyntheticEvent<{ menuId: string }>) => void;
  onDestinationOpen?: (e: NativeSyntheticEvent<{ destinationType: string, target: string }>) => void;
  
  style?: ViewStyle;
}

// Map RN Native view manager
const NativeMiniGameMenu = requireNativeComponent<NativeMiniGameMenuProps>('SimulaMiniGameMenu');

export interface MiniGameMenuProps {
  isOpen: boolean;
  charName: string;
  charID: string;
  charImage: string;
  messages?: Message[];
  charDesc?: string;
  convId?: string;
  entryPoint?: string;
  maxGamesToShow?: number;
  theme?: MiniGameTheme;
  delegateChar?: boolean;
  showBanner?: boolean;
  
  onGameOpen?: (event: { gameName: string, description: string }) => void;
  onGameClose?: (event: { gameName: string }) => void;
  onImpression?: (event: { menuId: string }) => void;
  onDestinationOpen?: (event: { destinationType: string, target: string }) => void;
  
  style?: ViewStyle;
}

export const MiniGameMenu: React.FC<MiniGameMenuProps> = ({
  isOpen,
  charName,
  charID,
  charImage,
  messages = [],
  charDesc,
  convId,
  entryPoint,
  maxGamesToShow = 6,
  theme = {},
  delegateChar = true,
  showBanner = true,
  onGameOpen,
  onGameClose,
  onImpression,
  onDestinationOpen,
  style,
}) => {
  if (!isOpen) {
    return null;
  }

  return (
    <NativeMiniGameMenu
      isOpen={isOpen}
      charName={charName}
      charID={charID}
      charImage={charImage}
      messages={messages}
      charDesc={charDesc}
      convId={convId}
      entryPoint={entryPoint}
      maxGamesToShow={maxGamesToShow}
      theme={theme}
      delegateChar={delegateChar}
      showBanner={showBanner}
      onGameOpen={(e) => onGameOpen?.(e.nativeEvent)}
      onGameClose={(e) => onGameClose?.(e.nativeEvent)}
      onImpression={(e) => onImpression?.(e.nativeEvent)}
      onDestinationOpen={(e) => onDestinationOpen?.(e.nativeEvent)}
      style={[StyleSheet.absoluteFillObject, style]}
    />
  );
};
