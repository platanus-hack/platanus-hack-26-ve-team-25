/**
 * En Casa - Definiciones de Tipos de Datos (TypeScript)
 * Proyecto Platanus Hack 26
 */

export interface KPIItem {
  icon: string;
  val: string;
  label: string;
  sub: string;
  color: string;
}

export interface MigrationTimeline {
  labels: number[];
  total: number[];
  americas: number[];
}

export interface CountryRanking {
  labels: string[];
  values: number[];
}

export interface AgeDemographics {
  labels: string[];
  values: number[];
  colors: string[];
}

export interface GlobalImpactStats {
  labels: string[];
  pctSolos: number[];
  colors: string[];
}

export interface ScalabilityMarket {
  labels: string[];
  millones: number[];
  colors: string[];
}

export interface ElderlyVulnerability {
  labels: string[];
  values: number[];
  colors: string[];
}

export interface DomesticAccidentStats {
  labels: string[];
  values: number[];
  colors: string[];
}

export interface EmergencyResponseTime {
  labels: string[];
  values: number[];
  colors: string[];
}

export interface RegionalVulnerability {
  labels: string[];
  vulnIdx: number[];
  hijosExt: number[];
}

export interface FlowStep {
  fase: string;
  icon: string;
  title: string;
  desc: string;
  badge: string;
}

export interface ReferenceItem {
  icon: string;
  title: string;
  year: string;
  desc: string;
  url: string;
}

export interface ProgressBarItem {
  label: string;
  val: number;
  color: string;
}
